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
# For PostgreSQL, we configure connection pooling and retry logic
if SQLALCHEMY_DATABASE_URL.startswith("sqlite"):
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL,
        connect_args={"check_same_thread": False}
    )
else:
    # PostgreSQL with connection pooling and resilience settings
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL,
        pool_pre_ping=True,  # Verify connections before using them
        pool_size=5,  # Number of connections to maintain
        max_overflow=10,  # Additional connections when pool is full
        pool_recycle=3600,  # Recycle connections after 1 hour
        connect_args={
            "connect_timeout": 10,  # 10 second connection timeout
            "keepalives": 1,
            "keepalives_idle": 30,
            "keepalives_interval": 10,
            "keepalives_count": 5
        }
    )

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
