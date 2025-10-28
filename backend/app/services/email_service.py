"""
Email service using Azure Communication Services.

Handles sending customer response emails and tracking delivery.
Uses Managed Identity for authentication (no connection strings).
"""

from azure.communication.email import EmailClient
from azure.identity import DefaultAzureCredential
from datetime import datetime
from typing import Optional
import logging

from ..config import settings
from ..models import EmailStatus

logger = logging.getLogger(__name__)


class EmailService:
    """Service for sending emails via Azure Communication Services"""
    
    def __init__(self):
        """Initialize email client with Managed Identity authentication"""
        if not settings.ACS_ENDPOINT:
            logger.warning("ACS_ENDPOINT not configured - email sending disabled")
            self.client = None
        else:
            try:
                # Use DefaultAzureCredential for Managed Identity authentication
                credential = DefaultAzureCredential()
                self.client = EmailClient(settings.ACS_ENDPOINT, credential)
                logger.info("Email client initialized with Managed Identity")
            except Exception as e:
                logger.error(f"Failed to initialize email client: {str(e)}")
                self.client = None
        
        self.sender_email = settings.ACS_SENDER_EMAIL
        self.company_name = settings.COMPANY_NAME
    
    def is_configured(self) -> bool:
        """Check if email service is properly configured"""
        return self.client is not None and self.sender_email is not None
    
    async def send_ticket_response(
        self,
        ticket_id: int,
        ticket_title: str,
        customer_email: str,
        customer_name: str,
        response_text: str,
        sent_by: Optional[str] = None
    ) -> tuple[EmailStatus, Optional[str], Optional[str]]:
        """
        Send email response to customer about their ticket.
        
        Args:
            ticket_id: ID of the ticket
            ticket_title: Title of the ticket
            customer_email: Customer's email address
            customer_name: Customer's name
            response_text: The response message to send
            sent_by: Name of employee sending the response
        
        Returns:
            Tuple of (status, message_id, error_message)
            - status: EmailStatus enum value
            - message_id: ACS message ID if successful
            - error_message: Error description if failed
        """
        
        if not self.is_configured():
            logger.error("Email service not configured")
            return (EmailStatus.FAILED, None, "Email service not configured")
        
        try:
            # Build email subject
            subject = f"{self.company_name} - Response to: {ticket_title}"
            
            # Build HTML email body
            html_body = self._build_email_html(
                customer_name=customer_name,
                ticket_id=ticket_id,
                ticket_title=ticket_title,
                response_text=response_text,
                sent_by=sent_by
            )
            
            # Build plain text version
            text_body = self._build_email_text(
                customer_name=customer_name,
                ticket_id=ticket_id,
                ticket_title=ticket_title,
                response_text=response_text,
                sent_by=sent_by
            )
            
            # Create email message using dict structure (compatible with azure-communication-email SDK)
            message = {
                "senderAddress": self.sender_email,
                "content": {
                    "subject": subject,
                    "plainText": text_body,
                    "html": html_body
                },
                "recipients": {
                    "to": [
                        {
                            "address": customer_email,
                            "displayName": customer_name
                        }
                    ]
                }
            }
            
            # Send email via ACS
            logger.info(f"Sending email to {customer_email} for ticket #{ticket_id}")
            poller = self.client.begin_send(message)
            result = poller.result()
            
            # Check if email was accepted
            if result and hasattr(result, 'message_id'):
                logger.info(f"Email sent successfully. Message ID: {result.message_id}")
                return (EmailStatus.SENT, result.message_id, None)
            else:
                logger.error("Email send failed - no message ID returned")
                return (EmailStatus.FAILED, None, "No message ID returned from ACS")
        
        except Exception as e:
            logger.error(f"Failed to send email: {str(e)}", exc_info=True)
            return (EmailStatus.FAILED, None, str(e))
    
    async def send_ticket_confirmation(
        self,
        ticket_id: int,
        ticket_title: str,
        customer_email: str,
        customer_name: str,
        ticket_description: str,
        ticket_category: str
    ) -> tuple[EmailStatus, Optional[str], Optional[str]]:
        """
        Send confirmation email to customer when they create a ticket.
        
        Args:
            ticket_id: ID of the ticket
            ticket_title: Title of the ticket
            customer_email: Customer's email address
            customer_name: Customer's name
            ticket_description: Description of the ticket
            ticket_category: Category of the ticket
        
        Returns:
            Tuple of (status, message_id, error_message)
        """
        
        if not self.is_configured():
            logger.error("Email service not configured")
            return (EmailStatus.FAILED, None, "Email service not configured")
        
        try:
            # Build email subject
            subject = f"{self.company_name} - Ticket #{ticket_id} Received"
            
            # Build HTML email body
            html_body = f"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
    
    <!-- Header -->
    <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 8px 8px 0 0;">
        <h1 style="color: white; margin: 0; font-size: 28px;">{self.company_name}</h1>
        <p style="color: rgba(255,255,255,0.9); margin: 10px 0 0 0; font-size: 16px;">Ticket Confirmation</p>
    </div>
    
    <!-- Body -->
    <div style="background: #ffffff; padding: 30px; border-left: 1px solid #e0e0e0; border-right: 1px solid #e0e0e0;">
        <p style="font-size: 16px; margin-bottom: 20px;">Hello {customer_name},</p>
        
        <p style="font-size: 16px; margin-bottom: 20px;">Thank you for contacting us! We have received your support request and our team will review it shortly.</p>
        
        <!-- Ticket Details Box -->
        <div style="background: #f5f5f5; border-left: 4px solid #667eea; padding: 15px; margin: 20px 0; border-radius: 4px;">
            <p style="margin: 0 0 8px 0; font-weight: 600; color: #666; font-size: 14px;">TICKET #{ticket_id}</p>
            <p style="margin: 0 0 8px 0; font-size: 18px; font-weight: 600; color: #333;">{ticket_title}</p>
            <p style="margin: 0; font-size: 14px; color: #666;">Category: {ticket_category}</p>
        </div>
        
        <!-- Description -->
        <div style="background: #ffffff; border: 1px solid #e0e0e0; padding: 20px; margin: 20px 0; border-radius: 4px;">
            <p style="font-weight: 600; margin: 0 0 12px 0; color: #667eea; font-size: 14px; text-transform: uppercase;">Your Message:</p>
            <div style="white-space: pre-wrap; font-size: 15px; line-height: 1.6; color: #333;">{ticket_description}</div>
        </div>
        
        <p style="font-size: 16px; margin-top: 20px;">We will get back to you as soon as possible. You can expect a response within 1-2 business days.</p>
        
        <p style="font-size: 16px; margin-top: 20px;">Thank you for your patience!</p>
        
        <p style="font-size: 16px; margin-top: 30px;">Best regards,<br>{self.company_name} Support Team</p>
    </div>
    
    <!-- Footer -->
    <div style="background: #f5f5f5; padding: 20px; text-align: center; border-radius: 0 0 8px 8px; border: 1px solid #e0e0e0; border-top: none;">
        <p style="font-size: 13px; color: #666; margin: 0;">This is an automated confirmation from {self.company_name}</p>
        <p style="font-size: 13px; color: #666; margin: 8px 0 0 0;">Please do not reply to this email</p>
    </div>
    
</body>
</html>
"""
            
            # Build plain text version
            text_body = f"""
{self.company_name} - Ticket Confirmation

Hello {customer_name},

Thank you for contacting us! We have received your support request and our team will review it shortly.

TICKET #{ticket_id}: {ticket_title}
Category: {ticket_category}

Your Message:
{ticket_description}

We will get back to you as soon as possible. You can expect a response within 1-2 business days.

Thank you for your patience!

Best regards,
{self.company_name} Support Team

---
This is an automated confirmation from {self.company_name}
Please do not reply to this email
"""
            
            # Create email message
            message = {
                "senderAddress": self.sender_email,
                "recipients": {
                    "to": [{"address": customer_email}]
                },
                "content": {
                    "subject": subject,
                    "plainText": text_body,
                    "html": html_body
                }
            }
            
            # Send email via ACS
            logger.info(f"Sending confirmation email to {customer_email} for ticket #{ticket_id}")
            poller = self.client.begin_send(message)
            result = poller.result()
            
            # Check if email was accepted
            if result and hasattr(result, 'message_id'):
                logger.info(f"Confirmation email sent successfully. Message ID: {result.message_id}")
                return (EmailStatus.SENT, result.message_id, None)
            else:
                logger.error("Confirmation email send failed - no message ID returned")
                return (EmailStatus.FAILED, None, "No message ID returned from ACS")
        
        except Exception as e:
            logger.error(f"Failed to send confirmation email: {str(e)}", exc_info=True)
            return (EmailStatus.FAILED, None, str(e))
    
    def _build_email_html(
        self,
        customer_name: str,
        ticket_id: int,
        ticket_title: str,
        response_text: str,
        sent_by: Optional[str]
    ) -> str:
        """Build professional HTML email template"""
        
        return f"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
    
    <!-- Header -->
    <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 8px 8px 0 0;">
        <h1 style="color: white; margin: 0; font-size: 28px;">{self.company_name}</h1>
        <p style="color: rgba(255,255,255,0.9); margin: 10px 0 0 0; font-size: 16px;">Case Response</p>
    </div>
    
    <!-- Body -->
    <div style="background: #ffffff; padding: 30px; border-left: 1px solid #e0e0e0; border-right: 1px solid #e0e0e0;">
        <p style="font-size: 16px; margin-bottom: 20px;">Hello {customer_name},</p>
        
        <p style="font-size: 16px; margin-bottom: 20px;">We have an update regarding your case:</p>
        
        <!-- Case Details Box -->
        <div style="background: #f5f5f5; border-left: 4px solid #667eea; padding: 15px; margin: 20px 0; border-radius: 4px;">
            <p style="margin: 0 0 8px 0; font-weight: 600; color: #666; font-size: 14px;">CASE #{ticket_id}</p>
            <p style="margin: 0; font-size: 16px; font-weight: 600; color: #333;">{ticket_title}</p>
        </div>
        
        <!-- Response -->
        <div style="background: #ffffff; border: 1px solid #e0e0e0; padding: 20px; margin: 20px 0; border-radius: 4px;">
            <p style="font-weight: 600; margin: 0 0 12px 0; color: #667eea; font-size: 14px; text-transform: uppercase;">Response:</p>
            <div style="white-space: pre-wrap; font-size: 15px; line-height: 1.6; color: #333;">{response_text}</div>
        </div>
        
        <p style="font-size: 16px; margin-top: 20px;">If you have any questions or need further assistance, please don't hesitate to reach out.</p>
        
        {"<p style='font-size: 15px; margin-top: 25px;'>Best regards,<br><strong>" + sent_by + "</strong><br>" + self.company_name + "</p>" if sent_by else "<p style='font-size: 15px; margin-top: 25px;'>Best regards,<br><strong>" + self.company_name + " Team</strong></p>"}
    </div>
    
    <!-- Footer -->
    <div style="background: #f5f5f5; padding: 20px; text-align: center; border-radius: 0 0 8px 8px; border: 1px solid #e0e0e0; border-top: none;">
        <p style="font-size: 13px; color: #666; margin: 0;">This is an automated message from {self.company_name}</p>
        <p style="font-size: 13px; color: #666; margin: 8px 0 0 0;">Please do not reply to this email</p>
    </div>
    
</body>
</html>
"""
    
    def _build_email_text(
        self,
        customer_name: str,
        ticket_id: int,
        ticket_title: str,
        response_text: str,
        sent_by: Optional[str]
    ) -> str:
        """Build plain text email version (fallback)"""
        
        signature = f"\n\nBest regards,\n{sent_by}\n{self.company_name}" if sent_by else f"\n\nBest regards,\n{self.company_name} Team"
        
        return f"""
{self.company_name} - Case Response

Hello {customer_name},

We have an update regarding your case:

CASE #{ticket_id}: {ticket_title}

Response:
{response_text}

If you have any questions or need further assistance, please don't hesitate to reach out.
{signature}

---
This is an automated message from {self.company_name}
Please do not reply to this email
"""


# Global email service instance
email_service = EmailService()


def get_email_service() -> EmailService:
    """Dependency injection for email service"""
    return email_service
