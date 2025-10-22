"""
Main FastAPI application entry point.

This file creates the FastAPI app and sets up:
- CORS (so frontend can call backend)
- Database initialization
- API routes
- Static file serving (for production)
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pathlib import Path
import os

from .database import engine, Base
from .routes import tickets

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Case Management API",
    description="API for managing support tickets and cases",
    version="1.0.0"
)

# CORS - Allow frontend (running on different port) to call this API
# In production, replace "*" with your actual frontend URL
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health check endpoint - useful for monitoring and CI/CD
@app.get("/health")
def health_check():
    """
    Health check endpoint for monitoring and load balancers.
    """
    return {"status": "ok"}


# Include ticket routes
app.include_router(tickets.router, prefix="/api/tickets", tags=["tickets"])

# Serve static frontend files (for production in Docker)
# Check if static directory exists (it won't in development)
static_dir = Path("/app/static")  # Absolute path in container
if not static_dir.exists():
    # Try relative path for development
    static_dir = Path(__file__).parent.parent.parent / "static"

if static_dir.exists():
    # Mount static assets (JS, CSS, images)
    app.mount("/assets", StaticFiles(directory=str(static_dir / "assets")), name="assets")
    
    # Serve index.html for root and any other routes (SPA routing)
    @app.get("/{full_path:path}")
    async def serve_spa(full_path: str):
        """Serve the React SPA for all non-API routes"""
        # Serve index.html for all routes (React Router handles it)
        index_file = static_dir / "index.html"
        if index_file.exists():
            return FileResponse(str(index_file))
        
        return {"error": "Frontend not found"}
else:
    # Development mode - show API is running
    @app.get("/")
    def read_root():
        """
        Simple health check endpoint (development only).
        Returns a message to confirm the API is running.
        """
        return {"message": "Case Management API is running", "status": "healthy"}
