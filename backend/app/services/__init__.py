"""
Services module - Business logic and external integrations.
"""

from .email_service import EmailService, email_service, get_email_service

__all__ = ['EmailService', 'email_service', 'get_email_service']
