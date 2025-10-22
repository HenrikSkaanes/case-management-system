"""
Pydantic schemas - Data validation and serialization.

Enhanced schemas for comprehensive case management with analytics support.
"""

from pydantic import BaseModel, Field, EmailStr
from datetime import datetime
from typing import Optional, List


class TicketBase(BaseModel):
    """Base schema with core ticket fields"""
    title: str = Field(..., min_length=1, max_length=200, description="Ticket title")
    description: Optional[str] = Field(None, description="Detailed description")
    category: str = Field(..., min_length=1, max_length=100, description="Category")
    priority: str = Field(default="medium", pattern="^(low|medium|high|critical)$")


class TicketCreate(TicketBase):
    """
    Schema for creating a new ticket.
    Includes customer information fields.
    """
    customer_name: Optional[str] = Field(None, max_length=200)
    customer_email: Optional[str] = Field(None)  # Could use EmailStr for validation
    customer_phone: Optional[str] = Field(None, max_length=50)
    customer_id: Optional[str] = Field(None, max_length=100)
    department: Optional[str] = Field(None, max_length=100)
    due_date: Optional[datetime] = None
    tags: Optional[List[str]] = None


class TicketUpdate(BaseModel):
    """
    Schema for updating an existing ticket.
    All fields optional for partial updates.
    """
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = None
    status: Optional[str] = Field(None, pattern="^(new|in_progress|pending_customer|resolved|closed|done)$")
    category: Optional[str] = Field(None, min_length=1, max_length=100)
    priority: Optional[str] = Field(None, pattern="^(low|medium|high|critical)$")
    
    # Customer fields
    customer_name: Optional[str] = Field(None, max_length=200)
    customer_email: Optional[str] = None
    customer_phone: Optional[str] = Field(None, max_length=50)
    customer_id: Optional[str] = Field(None, max_length=100)
    
    # Assignment fields
    assigned_to: Optional[str] = Field(None, max_length=200)
    department: Optional[str] = Field(None, max_length=100)
    
    # Timeline fields
    first_response_at: Optional[datetime] = None
    resolved_at: Optional[datetime] = None
    closed_at: Optional[datetime] = None
    due_date: Optional[datetime] = None
    
    # Analytics fields
    tags: Optional[List[str]] = None
    satisfaction_rating: Optional[int] = Field(None, ge=1, le=5)
    escalated: Optional[bool] = None
    notes: Optional[str] = None


class TicketResponse(TicketBase):
    """
    Complete ticket response with all fields.
    This is what the API returns.
    """
    id: int
    ticket_number: Optional[str] = None
    status: str
    
    # Customer information
    customer_name: Optional[str] = None
    customer_email: Optional[str] = None
    customer_phone: Optional[str] = None
    customer_id: Optional[str] = None
    
    # Assignment
    assigned_to: Optional[str] = None
    assigned_at: Optional[datetime] = None
    department: Optional[str] = None
    
    # Timeline
    created_at: datetime
    updated_at: Optional[datetime] = None
    first_response_at: Optional[datetime] = None
    resolved_at: Optional[datetime] = None
    closed_at: Optional[datetime] = None
    due_date: Optional[datetime] = None
    
    # Metrics
    response_time_minutes: Optional[int] = None
    resolution_time_minutes: Optional[int] = None
    
    # Analytics
    tags: Optional[List[str]] = None
    satisfaction_rating: Optional[int] = None
    reopened_count: Optional[int] = None
    escalated: Optional[bool] = None
    notes: Optional[str] = None

    class Config:
        """Pydantic configuration"""
        from_attributes = True  # Allows reading from SQLAlchemy models
