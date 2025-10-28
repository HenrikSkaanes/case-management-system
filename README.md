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

## 📊 Monitoring & Observability (NEW!)

This system includes **enterprise-grade monitoring** based on Azure Monitor Baseline Alerts (AMBA) with **FREE visualization options**:

### � Quick Setup Options

| Option | Time | Cost | Best For |
|--------|------|------|----------|
| **Dashboard** | 5 min | FREE | Quick overview |
| **Workbook** | 15 min | FREE | Deep analysis |
| **Alerts** | Auto | FREE* | Proactive notifications |

*Azure Monitor costs ~$80-100/month after free tier (log ingestion)

### 📈 Visualization Tools (All FREE!)

1. **Azure Dashboard** (Recommended for Beginners):
   - 📌 Pin metrics from resources
   - 🎨 Simple drag-and-drop
   - 📱 Mobile app support
   - ⏱️ Setup: [5-Minute Guide](docs/DASHBOARD_QUICK_SETUP.md)

2. **Azure Workbooks** (Recommended for Power Users):
   - 📊 Advanced charts + log queries
   - 🔍 Interactive parameters
   - 💾 Save & share templates
   - ⏱️ Setup: [15-Minute Guide](docs/WORKBOOK_SETUP.md)

3. **Azure Managed Grafana** (Optional - $240/month):
   - 🎨 Professional dashboards
   - 🌍 Multi-cloud support
   - 📚 1000+ community dashboards
   - ⏭️ Add later if needed

### 🔔 Alert Coverage

- 🐳 **Container Apps**: CPU, Memory, Restarts, 5xx errors
- 🗄️ **PostgreSQL**: CPU, Memory, Storage, Connections
- 🌐 **API Management**: Latency, Failures
- 📝 **Logs**: Application errors
- 🚨 **Activity**: Deletions, Security changes

### 📚 Documentation

| Guide | Purpose | Time |
|-------|---------|------|
| [Dashboard Setup](docs/DASHBOARD_QUICK_SETUP.md) | Quick visual monitoring | 5 min |
| [Workbook Setup](docs/WORKBOOK_SETUP.md) | Advanced analysis | 15 min |
| [Monitoring Guide](docs/MONITORING_GUIDE.md) | Complete reference | - |
| [Quick Start](docs/QUICK_START_MONITORING.md) | Deploy alerts | 5 min |

### 🎯 Recommended Approach

**Day 1** (After Deployment):
```bash
# 1. Deploy infrastructure with monitoring
az deployment group create \
  --template-file infra/bicep/main.bicep \
  --parameters alertEmails='["your-email@example.com"]'

# 2. Create quick dashboard (5 min)
# Follow: docs/DASHBOARD_QUICK_SETUP.md
```

**Week 1** (When You Have Time):
```bash
# 3. Create detailed workbook (15 min)
# Follow: docs/WORKBOOK_SETUP.md
```

**Month 2+** (If Needed):
```bash
# 4. Consider Grafana for professional dashboards
# Cost: $240/month
```

### What is AMBA?

**Azure Monitor Baseline Alerts (AMBA)** is Microsoft's framework for production-ready monitoring:
- ✅ Expert-curated alert thresholds
- ✅ Service-specific recommendations
- ✅ Free to use (you only pay for Azure Monitor)
- ✅ Battle-tested across thousands of deployments

Learn more: https://azure.github.io/azure-monitor-baseline-alerts/

## Features

- ✅ Create, view, update, delete tickets
- ✅ Kanban board view (New → In Progress → Done)
- ✅ Category filtering
- ✅ Priority levels
- ✅ Email notifications via Azure Communication Services
- ✅ Logic Apps workflow automation
- ✅ **Production-grade monitoring & alerting** (NEW!)
  - 13 pre-configured alerts based on Azure Monitor Baseline Alerts (AMBA)
  - Critical & warning notification channels
  - Application Insights integration ready
  - Custom dashboards & workbooks
- ✅ CI/CD with GitHub Actions
- ✅ Azure Container Apps deployment
- ✅ Enterprise-grade security (VNet, Private Endpoints, WAF)

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

**Monitoring & Observability:**
- Azure Monitor (based on AMBA best practices)
- Log Analytics
- Metric & Log-based alerts
- Action Groups (Email, SMS, Teams, Slack)
- Custom workbooks & dashboards
- Azure Verified Modules (AVM) compatible
