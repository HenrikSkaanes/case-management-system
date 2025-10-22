"""
Database models - Python classes that represent database tables.

Enhanced Ticket model with comprehensive fields for analytics and case management.
Includes TicketResponse model for tracking email communications.
"""

from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text, JSON, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime
import enum

from .database import Base


class TicketStatus(str, enum.Enum):
    """Ticket lifecycle status"""
    NEW = "new"
    IN_PROGRESS = "in_progress"
    PENDING_CUSTOMER = "pending_customer"  # Waiting for customer response
    RESOLVED = "resolved"  # Fixed, awaiting closure
    CLOSED = "closed"  # Fully closed
    DONE = "done"  # Legacy compatibility


class TicketPriority(str, enum.Enum):
    """Priority levels"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class EmailStatus(str, enum.Enum):
    """Email delivery status"""
    PENDING = "pending"
    SENT = "sent"
    FAILED = "failed"
    DELIVERED = "delivered"  # Confirmed delivery (if tracking enabled)


class Ticket(Base):
    """
    Enhanced Ticket/Case model for comprehensive case management.
    
    Includes fields for:
    - Customer information
    - Assignment tracking
    - SLA/timeline metrics
    - Analytics data
    """
    __tablename__ = "tickets"

    # Primary Key
    id = Column(Integer, primary_key=True, index=True)
    
    # Ticket Information
    ticket_number = Column(String, unique=True, index=True, nullable=True)  # e.g., "TAX-2025-0001"
    title = Column(String, nullable=False, index=True)
    description = Column(Text, nullable=True)
    category = Column(String, nullable=False, index=True)  # income_tax, vat, deductions, etc.
    priority = Column(String, default=TicketPriority.MEDIUM, nullable=False, index=True)
    status = Column(String, default=TicketStatus.NEW, nullable=False, index=True)
    
    # Customer Information
    customer_name = Column(String, nullable=True, index=True)
    customer_email = Column(String, nullable=True, index=True)
    customer_phone = Column(String, nullable=True)
    customer_id = Column(String, nullable=True, index=True)  # External reference ID
    
    # Assignment & Ownership
    assigned_to = Column(String, nullable=True, index=True)  # Employee name/ID
    assigned_at = Column(DateTime(timezone=True), nullable=True)
    department = Column(String, nullable=True, index=True)  # returns, compliance, general
    
    # Timeline & SLA Tracking
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False, index=True)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now(), server_default=func.now())
    first_response_at = Column(DateTime(timezone=True), nullable=True)
    resolved_at = Column(DateTime(timezone=True), nullable=True)
    closed_at = Column(DateTime(timezone=True), nullable=True)
    due_date = Column(DateTime(timezone=True), nullable=True)
    
    # Calculated metrics (in minutes) - can be computed or stored
    response_time_minutes = Column(Integer, nullable=True)  # Time to first response
    resolution_time_minutes = Column(Integer, nullable=True)  # Time to resolution
    
    # Analytics & Additional Data
    tags = Column(JSON, nullable=True)  # Array of tags: ["urgent", "vip", "complex"]
    satisfaction_rating = Column(Integer, nullable=True)  # 1-5 stars
    reopened_count = Column(Integer, default=0)  # How many times reopened
    escalated = Column(Boolean, default=False)  # Escalated to supervisor
    notes = Column(Text, nullable=True)  # Internal notes

    # Relationship to responses
    responses = relationship("TicketResponse", back_populates="ticket", cascade="all, delete-orphan")

    def __repr__(self):
        """String representation for debugging"""
        return f"<Ticket {self.ticket_number or self.id}: {self.title} ({self.status})>"


class TicketResponse(Base):
    """
    Track all email responses sent to customers for tickets.
    
    Provides audit trail and communication history.
    """
    __tablename__ = "ticket_responses"

    # Primary Key
    id = Column(Integer, primary_key=True, index=True)
    
    # Foreign Key to Ticket
    ticket_id = Column(Integer, ForeignKey('tickets.id', ondelete='CASCADE'), nullable=False, index=True)
    
    # Email Details
    subject = Column(String, nullable=False)
    response_text = Column(Text, nullable=False)
    sent_to = Column(String, nullable=False, index=True)  # Customer email
    sent_by = Column(String, nullable=True)  # Employee name/ID who sent it
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    sent_at = Column(DateTime(timezone=True), nullable=True)  # When email was actually sent
    
    # Status & Error Tracking
    email_status = Column(String, default=EmailStatus.PENDING, nullable=False, index=True)
    error_message = Column(Text, nullable=True)  # Store error if sending failed
    
    # Azure Communication Services metadata
    message_id = Column(String, nullable=True)  # ACS message ID for tracking
    
    # Relationship to ticket
    ticket = relationship("Ticket", back_populates="responses")

    def __repr__(self):
        """String representation for debugging"""
        return f"<TicketResponse {self.id}: Ticket #{self.ticket_id} to {self.sent_to} ({self.email_status})>"
