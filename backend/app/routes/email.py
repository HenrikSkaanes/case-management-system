"""
Email routes - API endpoints for sending email responses to customers.

Handles ticket response emails and tracks communication history.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime
import logging

from ..database import get_db
from ..models import Ticket, TicketResponse, EmailStatus
from ..schemas import EmailResponseCreate, EmailResponseResponse
from ..services.email_service import get_email_service, EmailService

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post(
    "/tickets/{ticket_id}/respond",
    response_model=EmailResponseResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Send email response to customer",
    description="Sends an email response to the customer and saves it to the database"
)
async def send_ticket_response(
    ticket_id: int,
    response_data: EmailResponseCreate,
    db: Session = Depends(get_db),
    email_service: EmailService = Depends(get_email_service)
):
    """
    Send an email response to a customer about their ticket.
    
    - **ticket_id**: ID of the ticket to respond to
    - **response**: The message to send to the customer
    - **customer_email**: Customer's email address
    - **customer_name**: Customer's name
    - **ticket_title**: Title of the ticket
    - **sent_by**: Optional name of employee sending the response
    
    Returns the created response record with email status.
    """
    
    # 1. Verify ticket exists
    ticket = db.query(Ticket).filter(Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Ticket with id {ticket_id} not found"
        )
    
    # 2. Check if email service is configured
    if not email_service.is_configured():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Email service is not configured. Please configure ACS_CONNECTION_STRING and ACS_SENDER_EMAIL."
        )
    
    # 3. Create response record in database (pending state)
    db_response = TicketResponse(
        ticket_id=ticket_id,
        subject=f"{email_service.company_name} - Response to: {response_data.ticket_title}",
        response_text=response_data.response,
        sent_to=response_data.customer_email,
        sent_by=response_data.sent_by,
        email_status=EmailStatus.PENDING
    )
    db.add(db_response)
    db.commit()
    db.refresh(db_response)
    
    # 4. Send email via Azure Communication Services
    try:
        email_status, message_id, error_message = await email_service.send_ticket_response(
            ticket_id=ticket_id,
            ticket_title=response_data.ticket_title,
            customer_email=response_data.customer_email,
            customer_name=response_data.customer_name,
            response_text=response_data.response,
            sent_by=response_data.sent_by
        )
        
        # 5. Update response record with result
        db_response.email_status = email_status
        db_response.message_id = message_id
        db_response.error_message = error_message
        
        if email_status == EmailStatus.SENT:
            db_response.sent_at = datetime.utcnow()
            
            # Update ticket's first_response_at if this is the first response
            if ticket.first_response_at is None:
                ticket.first_response_at = datetime.utcnow()
                
                # Calculate response time if possible
                if ticket.created_at:
                    delta = datetime.utcnow() - ticket.created_at.replace(tzinfo=None)
                    ticket.response_time_minutes = int(delta.total_seconds() / 60)
        
        db.commit()
        db.refresh(db_response)
        
        logger.info(f"Email response sent for ticket #{ticket_id}, status: {email_status}")
        
        return db_response
    
    except Exception as e:
        # Update record with error
        db_response.email_status = EmailStatus.FAILED
        db_response.error_message = str(e)
        db.commit()
        db.refresh(db_response)
        
        logger.error(f"Failed to send email for ticket #{ticket_id}: {str(e)}")
        
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to send email: {str(e)}"
        )


@router.get(
    "/tickets/{ticket_id}/responses",
    response_model=list[EmailResponseResponse],
    summary="Get all responses for a ticket",
    description="Retrieves all email responses sent for a specific ticket"
)
def get_ticket_responses(
    ticket_id: int,
    db: Session = Depends(get_db)
):
    """
    Get all email responses for a ticket.
    
    - **ticket_id**: ID of the ticket
    
    Returns list of all responses sent for this ticket.
    """
    
    # Verify ticket exists
    ticket = db.query(Ticket).filter(Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Ticket with id {ticket_id} not found"
        )
    
    # Get all responses for this ticket
    responses = db.query(TicketResponse).filter(
        TicketResponse.ticket_id == ticket_id
    ).order_by(TicketResponse.created_at.desc()).all()
    
    return responses
