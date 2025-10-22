# 🎯 Changes Summary - Monolith to Microservices

## ✅ Completed Changes:

### 1. **Backend (API Only)**
- ✅ Created `backend/Dockerfile` - Builds API-only container
- ✅ Updated `backend/app/main.py` - Removed static file serving, API-only
- ✅ Updated CORS to allow Static Web App domain

### 2. **Frontend (Static Web App)**
- ✅ Updated `frontend/src/services/api.js` - Uses environment variable for API URL
- ✅ Created `frontend/staticwebapp.config.json` - Static Web App configuration

### 3. **Infrastructure (Bicep)**
- ✅ Created `infra/bicep/modules/staticwebapp.bicep` - Static Web App module
- ✅ Updated `infra/bicep/main.bicep` - Deploys both Static Web App + Container App
- ✅ Kept existing modules (ACR, Logs, Environment, App)

### 4. **Documentation**
- ✅ Created `ARCHITECTURE.md` - Explains the new architecture
- ✅ This file - Tracks all changes

---

## ⏳ Next Steps:

### 1. **Update GitHub Actions Workflows**

We need to create/update 3 workflows:

#### **A. `.github/workflows/deploy-infrastructure.yml`** (NEW)
- Deploys Bicep infrastructure
- Runs only when infrastructure changes
- Outputs: API URL, deployment tokens

#### **B. `.github/workflows/deploy-backend.yml`** (UPDATED)
- Builds backend Docker image
- Pushes to ACR
- Updates Container App
- Trigger: changes to `backend/**`

#### **C. `.github/workflows/deploy-frontend.yml`** (NEW)
- Builds React app
- Deploys to Static Web App
- Configures API URL
- Trigger: changes to `frontend/**`

### 2. **GitHub Secrets Needed**

Already have:
- ✅ `AZURE_CREDENTIALS` - For Azure deployments

Need to add (after first infrastructure deploy):
- ⏳ `STATIC_WEB_APP_DEPLOYMENT_TOKEN` - For frontend deployment

---

## 📁 File Changes Summary:

### **Removed:**
```
❌ Dockerfile (root) - Was building monolith
❌ .github/workflows/deploy.yml - Was deploying monolith
❌ .github/workflows/deploy-app-only.yml - Not needed with separation
```

### **Added:**
```
✅ backend/Dockerfile - API-only container
✅ frontend/staticwebapp.config.json - Static Web App config
✅ infra/bicep/modules/staticwebapp.bicep - Frontend infrastructure
✅ ARCHITECTURE.md - Architecture documentation
✅ MIGRATION_SUMMARY.md - This file
```

### **Updated:**
```
🔄 backend/app/main.py - Removed static serving, updated CORS
🔄 frontend/src/services/api.js - Environment variable for API URL
🔄 infra/bicep/main.bicep - Deploy both frontend + backend
```

### **To be created:**
```
⏳ .github/workflows/deploy-infrastructure.yml
⏳ .github/workflows/deploy-backend.yml
⏳ .github/workflows/deploy-frontend.yml
```

---

## 🎯 Deployment Flow (New):

### **One-time Infrastructure Setup:**
```bash
1. Run: deploy-infrastructure.yml
2. Creates: ACR, Logs, Environment, Container App, Static Web App
3. Takes: ~10 minutes
4. Outputs: API URL, deployment tokens
5. Manually add deployment token to GitHub secrets
```

### **Regular Development:**

#### **Backend Changes:**
```bash
1. Edit: backend/app/*.py
2. Commit & push
3. Triggers: deploy-backend.yml
4. Takes: ~5 minutes
5. Updates: API only
```

#### **Frontend Changes:**
```bash
1. Edit: frontend/src/*.jsx
2. Commit & push
3. Triggers: deploy-frontend.yml
4. Takes: ~2 minutes
5. Updates: Frontend only (on CDN)
```

#### **Both Changes:**
```bash
1. Edit: both frontend/ and backend/
2. Commit & push
3. Triggers: BOTH workflows (parallel!)
4. Takes: ~5 minutes (parallel execution)
5. Updates: Both independently
```

---

## 💰 Cost Impact:

### **Before:**
```
Single Container App: ~$46/month
```

### **After:**
```
Static Web App (Free tier): $0/month
Container App API (0.25 vCPU, 0.5 GB): ~$23/month
----------------------------------------
Total: $23/month (50% savings!)
```

**Plus:**
- ✅ Faster frontend (CDN vs container)
- ✅ Global distribution
- ✅ Can scale backend to 0 when idle
- ✅ Independent scaling

---

## 🔍 What to Verify After Deployment:

### **Infrastructure:**
```bash
az resource list --resource-group rg-case-management-dev --output table

Expected resources:
- acrcasemanagementdev (Container Registry)
- log-casemanagement-dev (Log Analytics)
- cae-casemanagement-dev (Container App Environment)
- ca-api-casemanagement-dev (Container App - API)
- stapp-casemanagement-dev (Static Web App)
```

### **Frontend:**
```bash
# Check Static Web App
curl https://stapp-casemanagement-dev.azurestaticapps.net

# Should return: HTML (React app)
```

### **Backend:**
```bash
# Check API health
curl https://ca-api-casemanagement-dev.norwayeast.azurecontainerapps.io/health

# Should return: {"status": "ok"}

# Check API docs
open https://ca-api-casemanagement-dev.norwayeast.azurecontainerapps.io/docs
```

### **Integration:**
```bash
# Open frontend in browser
open https://stapp-casemanagement-dev.azurestaticapps.net

# Check browser console - should see API calls to Container App
# Should be able to create/update/delete tickets
```

---

## 🐛 Common Issues & Solutions:

### **Issue: Frontend can't reach backend**
**Solution:**
```
1. Check CORS in backend/app/main.py
2. Verify API URL in Static Web App settings
3. Check browser console for errors
```

### **Issue: Static Web App deployment fails**
**Solution:**
```
1. Verify deployment token is correct
2. Check GitHub Actions logs
3. Ensure frontend/dist/ builds correctly locally
```

### **Issue: Backend returns 500 error**
**Solution:**
```
1. Check Container App logs:
   az containerapp logs show --name ca-api-casemanagement-dev --resource-group rg-case-management-dev --follow
2. Check for missing environment variables
3. Verify database connection
```

---

## 📊 Architecture Diagram:

```
┌─────────────────────────────────────────────────────┐
│  User's Browser                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │  React App (running in browser)               │ │
│  │  - Loaded from Static Web App (CDN)           │ │
│  │  - Makes API calls to Container App           │ │
│  └─────────┬─────────────────────────────────────┘ │
└────────────┼───────────────────────────────────────┘
             │
             │ GET /index.html, /bundle.js
             ▼
┌────────────────────────────────────┐
│  Azure Static Web App              │
│  - Global CDN distribution         │
│  - Serves: HTML, JS, CSS           │
│  - Cost: $0/month (Free tier)      │
│  - Deploy: GitHub Actions          │
└────────────────────────────────────┘
             │
             │ POST /api/tickets (CORS allowed)
             ▼
┌────────────────────────────────────┐
│  Azure Container App (API)         │
│  - Docker container from ACR       │
│  - Runs: FastAPI (Python)          │
│  - Serves: JSON API only           │
│  - Cost: ~$23/month                │
│  - Scales: 1-5 instances           │
└────────────────────────────────────┘
             │
             │ Stores data
             ▼
┌────────────────────────────────────┐
│  SQLite Database                   │
│  - In container (ephemeral)        │
│  - Future: PostgreSQL              │
└────────────────────────────────────┘
```

---

Ready to create the GitHub Actions workflows? 🚀
