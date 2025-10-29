"""
API route handlers for ticket operations.

This file contains all the endpoints for managing tickets:
- GET /tickets - List all tickets (with optional filtering)
- GET /tickets/{id} - Get single ticket
- POST /tickets - Create new ticket
- PUT /tickets/{id} - Update ticket
- DELETE /tickets/{id} - Delete ticket
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
import logging

from ..database import get_db
from ..models import Ticket, TicketStatus
from ..schemas import TicketCreate, TicketUpdate, TicketResponse

logger = logging.getLogger(__name__)

# Create router - this groups related endpoints
router = APIRouter()


@router.get("/", response_model=List[TicketResponse])
def get_tickets(
    status: Optional[str] = Query(None, description="Filter by status"),
    category: Optional[str] = Query(None, description="Filter by category"),
    db: Session = Depends(get_db)
):
    """
    Get all tickets with optional filtering.
    
    Query parameters:
    - status: Filter by status (new, in_progress, done)
    - category: Filter by category
    
    Example: GET /tickets?status=new&category=Tax
    """
    query = db.query(Ticket)
    
    # Apply filters if provided
    if status:
        query = query.filter(Ticket.status == status)
    if category:
        query = query.filter(Ticket.category == category)
    
    tickets = query.order_by(Ticket.created_at.desc()).all()
    return tickets


@router.get("/{ticket_id}", response_model=TicketResponse)
def get_ticket(ticket_id: int, db: Session = Depends(get_db)):
    """
    Get a single ticket by ID.
    
    Returns 404 if ticket doesn't exist.
    """
    ticket = db.query(Ticket).filter(Ticket.id == ticket_id).first()
    
    if not ticket:
        raise HTTPException(status_code=404, detail=f"Ticket {ticket_id} not found")
    
    return ticket


@router.post("/", response_model=TicketResponse, status_code=201)
def create_ticket(ticket_data: TicketCreate, db: Session = Depends(get_db)):
    """
    Create a new ticket.
    
    Request body should contain:
    - title: Required
    - description: Optional
    - category: Required
    - priority: Optional (defaults to 'medium')
    - customer_name: Required
    - customer_email: Required (must be valid email)
    - customer_phone: Optional
    - And other optional fields for assignment, analytics, etc.
    
    Returns the created ticket with ID and timestamps.
    """
    # Create new Ticket instance with all fields from schema
    ticket_dict = ticket_data.model_dump(exclude_unset=True)
    
    # Ensure status is set to NEW for new tickets
    ticket_dict['status'] = TicketStatus.NEW
    
    new_ticket = Ticket(**ticket_dict)
    
    # Add to database
    db.add(new_ticket)
    db.commit()
    db.refresh(new_ticket)  # Get the auto-generated ID
    
    # TODO: Add confirmation email in background task
    # Currently disabled due to runtime issues
    
    return new_ticket


@router.put("/{ticket_id}", response_model=TicketResponse)
def update_ticket(
    ticket_id: int, 
    ticket_data: TicketUpdate, 
    db: Session = Depends(get_db)
):
    """
    Update an existing ticket.
    
    Only provided fields will be updated.
    Returns 404 if ticket doesn't exist.
    """
    # Find ticket
    ticket = db.query(Ticket).filter(Ticket.id == ticket_id).first()
    
    if not ticket:
        raise HTTPException(status_code=404, detail=f"Ticket {ticket_id} not found")
    
    # Update only provided fields
    update_data = ticket_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(ticket, field, value)
    
    db.commit()
    db.refresh(ticket)
    
    return ticket


@router.delete("/{ticket_id}", status_code=204)
def delete_ticket(ticket_id: int, db: Session = Depends(get_db)):
    """
    Delete a ticket.
    
    Returns 204 No Content on success.
    Returns 404 if ticket doesn't exist.
    """
    ticket = db.query(Ticket).filter(Ticket.id == ticket_id).first()
    
    if not ticket:
        raise HTTPException(status_code=404, detail=f"Ticket {ticket_id} not found")
    
    db.delete(ticket)
    db.commit()
    
    return None  # 204 returns no content
