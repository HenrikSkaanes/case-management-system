"""
Backend API for Case Management System.
This file creates the FastAPI app and sets up:
- CORS (so Static Web App frontend can call this API)
- Database initialization
- API routes
- NO static file serving (frontend is on Static Web App)
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .database import engine, Base
from .routes import tickets, email

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Case Management API",
    description="Backend API for managing support tickets and cases with email notifications",
    version="2.1.0"  # Added Azure Communication Services
)

# NOTE: 2025-10-28 Trigger rebuild to ensure azure-communication-email dependency is baked into image

# CORS - Allow Static Web App frontend to call this API
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",                                      # Vite dev server (local development)
        "http://localhost:3000",                                      # Alternative local port
        "https://zealous-hill-04965a603.3.azurestaticapps.net",      # Azure Static Web App (production)
        # Add your custom domain here when you set one up
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Root endpoint - shows API is running
@app.get("/")
def root():
    """
    API root endpoint.
    """
    return {
        "message": "Case Management API",
        "version": "2.1.0",
        "status": "running",
        "docs": "/docs",  # Swagger UI
        "redoc": "/redoc"  # ReDoc UI
    }

# Health check endpoint - for monitoring and load balancers
@app.get("/health")
def health_check():
    """
    Health check endpoint for monitoring, Azure health probes, and CI/CD.
    """
    return {"status": "ok"}

# Include ticket routes
app.include_router(tickets.router, prefix="/api/tickets", tags=["tickets"])

# Include email routes
app.include_router(email.router, prefix="/api", tags=["email"])
