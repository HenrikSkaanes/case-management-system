"""
Pydantic schemas - Data validation and serialization.

These schemas define:
1. What data the API accepts (request validation)
2. What data the API returns (response serialization)
3. Data types and validation rules

Why separate from models?
- Models = Database structure (SQLAlchemy)
- Schemas = API contract (Pydantic)
- Keeps concerns separated
"""

from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional


class TicketBase(BaseModel):
    """
    Base schema with common fields.
    Other schemas inherit from this.
    """
    title: str = Field(..., min_length=1, max_length=200, description="Ticket title")
    description: Optional[str] = Field(None, description="Detailed description")
    category: str = Field(..., min_length=1, max_length=100, description="Category (e.g., Tax, VAT)")
    priority: str = Field(default="medium", pattern="^(low|medium|high)$", description="Priority level")


class TicketCreate(TicketBase):
    """
    Schema for creating a new ticket.
    
    Used when client sends POST request to create ticket.
    Inherits all fields from TicketBase.
    """
    pass


class TicketUpdate(BaseModel):
    """
    Schema for updating an existing ticket.
    
    All fields are optional - you can update just one field.
    Used for PUT/PATCH requests.
    """
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = None
    status: Optional[str] = Field(None, pattern="^(new|in_progress|done)$")
    category: Optional[str] = Field(None, min_length=1, max_length=100)
    priority: Optional[str] = Field(None, pattern="^(low|medium|high)$")


class TicketResponse(TicketBase):
    """
    Schema for returning ticket data to client.
    
    Includes all fields plus auto-generated ones (id, timestamps).
    This is what the API sends back.
    """
    id: int
    status: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        """
        Pydantic configuration.
        orm_mode allows Pydantic to read data from SQLAlchemy models.
        """
        from_attributes = True  # Updated in Pydantic v2 (was orm_mode)
