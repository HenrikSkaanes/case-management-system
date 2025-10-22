"""
Database configuration and setup.

This file sets up SQLAlchemy to work with PostgreSQL.
SQLAlchemy is an ORM (Object-Relational Mapper) - it lets us work with 
database tables as if they were Python objects.
"""

import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Get database URL from environment variable, fallback to SQLite for local dev
SQLALCHEMY_DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "sqlite:///./tickets.db"  # Fallback for local development
)

# Create database engine
# For SQLite, we need check_same_thread=False
# For PostgreSQL, we don't need any special connect_args
if SQLALCHEMY_DATABASE_URL.startswith("sqlite"):
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL,
        connect_args={"check_same_thread": False}
    )
else:
    # PostgreSQL doesn't need special connect_args
    engine = create_engine(SQLALCHEMY_DATABASE_URL)

# SessionLocal: each instance is a database session
# We'll use this to interact with the database
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base: all database models will inherit from this
Base = declarative_base()


def get_db():
    """
    Dependency function to get database session.
    
    This is used in FastAPI routes to get a database connection.
    It ensures the connection is properly closed after use.
    
    Usage in routes:
        def some_route(db: Session = Depends(get_db)):
            # use db here
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
