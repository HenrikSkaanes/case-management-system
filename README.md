# Case Management System

A ticketing/case management system with Kanban board interface, built with FastAPI backend and React frontend.

## Project Structure

```
case-management-system/
├── backend/              # FastAPI application
│   ├── app/
│   │   ├── main.py      # FastAPI app entry point
│   │   ├── models.py    # Database models
│   │   ├── schemas.py   # Pydantic schemas (data validation)
│   │   ├── database.py  # Database connection
│   │   └── routes/      # API endpoints
│   ├── tests/           # Backend tests
│   └── requirements.txt # Python dependencies
├── frontend/            # React application
│   ├── src/
│   │   ├── App.jsx
│   │   ├── components/
│   │   └── services/    # API calls
│   └── package.json
├── Dockerfile           # Container definition
├── docker-compose.yml   # Local development setup
└── .gitignore
```

## Getting Started

### Prerequisites
- Python 3.11+
- Node.js 18+
- Docker (optional, for containerization)

### Local Development

1. **Backend Setup**
   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   uvicorn app.main:app --reload
   ```
   Backend runs at: http://localhost:8000

2. **Frontend Setup**
   ```bash
   cd frontend
   npm install
   npm run dev
   ```
   Frontend runs at: http://localhost:5173

## Features

- ✅ Create, view, update, delete tickets
- ✅ Kanban board view (New → In Progress → Done)
- ✅ Category filtering
- ✅ Priority levels
- 🔄 CI/CD with GitHub Actions (coming soon)
- 🔄 Azure Container Apps deployment (coming soon)

## Tech Stack

**Backend:**
- FastAPI (Python web framework)
- SQLite (Database)
- Pydantic (Data validation)
- SQLAlchemy (ORM)

**Frontend:**
- React + Vite
- CSS (or Tailwind later)

**DevOps:**
- Docker
- GitHub Actions
- Azure Container Apps
