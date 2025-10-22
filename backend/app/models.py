"""
Database models - Python classes that represent database tables.

This Ticket model will become a 'tickets' table in SQLite.
Each instance of this class represents one row in the table.
"""

from sqlalchemy import Column, Integer, String, DateTime, Enum
from sqlalchemy.sql import func
from datetime import datetime
import enum

from .database import Base


class TicketStatus(str, enum.Enum):
    """
    Enum for ticket status - restricts values to these three options.
    This ensures data consistency.
    """
    NEW = "new"
    IN_PROGRESS = "in_progress"
    DONE = "done"


class TicketPriority(str, enum.Enum):
    """
    Enum for ticket priority levels.
    """
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class Ticket(Base):
    """
    Ticket model - represents a support ticket/case.
    
    This will create a table with these columns:
    - id: Primary key (auto-incremented)
    - title: Short description
    - description: Full details
    - status: new, in_progress, or done
    - category: e.g., "Tax", "VAT", "Fees"
    - priority: low, medium, or high
    - created_at: When the ticket was created
    - updated_at: When the ticket was last modified
    """
    __tablename__ = "tickets"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(String, nullable=True)
    status = Column(String, default=TicketStatus.NEW, nullable=False)
    category = Column(String, nullable=False)
    priority = Column(String, default=TicketPriority.MEDIUM, nullable=False)
    
    # Timestamps - automatically managed
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    def __repr__(self):
        """String representation for debugging"""
        return f"<Ticket {self.id}: {self.title} ({self.status})>"
