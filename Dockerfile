# Multi-stage Dockerfile
# Stage 1: Build React frontend
# Stage 2: Python backend + serve frontend

# ============================================
# STAGE 1: Build Frontend (Node.js)
# ============================================
FROM node:18-alpine AS frontend-builder

# Set working directory for frontend build
WORKDIR /frontend

# Copy package files
COPY frontend/package*.json ./

# Install dependencies
RUN npm install

# Copy frontend source code
COPY frontend/ ./

# Build the React app (creates /frontend/dist with static files)
RUN npm run build

# ============================================
# STAGE 2: Python Backend + Serve Frontend
# ============================================
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies (if needed)
RUN apt-get update && apt-get install -y \
    && rm -rf /var/lib/apt/lists/*

# Copy backend requirements
COPY backend/requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend application code
COPY backend/app ./app

# Copy built frontend from stage 1
# This copies the compiled React app into the backend
COPY --from=frontend-builder /frontend/dist ./static

# Create directory for database
RUN mkdir -p /app/data

# Expose port 8000
EXPOSE 8000

# Environment variables
ENV PYTHONUNBUFFERED=1

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

# Run the application
# Note: We'll modify main.py to serve the static frontend files
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
