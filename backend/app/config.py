"""
Configuration management using environment variables.

Loads settings from environment variables or .env file.
"""

import os
from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""
    
    # Database
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./tickets.db")
    
    # Azure Communication Services - Using Connection String
    ACS_CONNECTION_STRING: Optional[str] = os.getenv("ACS_CONNECTION_STRING")
    ACS_SENDER_EMAIL: Optional[str] = os.getenv("ACS_SENDER_EMAIL")
    
    # Company branding
    COMPANY_NAME: str = os.getenv("COMPANY_NAME", "Wrangler Tax Services")
    
    # API Configuration
    API_V1_STR: str = "/api"
    PROJECT_NAME: str = "Case Management System"
    
    class Config:
        env_file = ".env"
        case_sensitive = True


# Global settings instance
settings = Settings()


def get_settings() -> Settings:
    """Dependency injection for settings"""
    return settings
