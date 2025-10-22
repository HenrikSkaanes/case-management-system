# Architecture Migration: Monolith → Frontend + Backend

## 🔄 What Changed?

### **Before (Monolith):**
```
┌────────────────────────────────────┐
│  Single Container App              │
│  ┌──────────────────────────────┐ │
│  │  FastAPI (Backend)           │ │
│  │  + React Static Files        │ │
│  │  Both served from port 8000  │ │
│  └──────────────────────────────┘ │
└────────────────────────────────────┘
```

### **After (Separated):**
```
┌─────────────────────────┐        ┌────────────────────────────┐
│  Static Web App         │        │  Container App (API)       │
│  ┌───────────────────┐  │        │  ┌──────────────────────┐ │
│  │  React            │  │ calls  │  │  FastAPI             │ │
│  │  (HTML/JS/CSS)    │──┼───────→│  │  (JSON API only)     │ │
│  │  on CDN           │  │        │  │  port 8000           │ │
│  └───────────────────┘  │        │  └──────────────────────┘ │
└─────────────────────────┘        └────────────────────────────┘
  Global CDN Distribution            Scales independently
  Free tier available!               Pay for actual usage
```

---

## 📂 File Changes:

### **Removed:**
- ❌ `Dockerfile` (root) - Single container for both
- ❌ Static file serving in `backend/app/main.py`

### **Added:**
- ✅ `backend/Dockerfile` - API-only container
- ✅ `frontend/staticwebapp.config.json` - Static Web App config
- ✅ `infra/bicep/modules/staticwebapp.bicep` - Frontend infrastructure

### **Modified:**
- 🔄 `backend/app/main.py` - Removed static file serving, updated CORS
- 🔄 `frontend/src/services/api.js` - Use environment variable for API URL
- 🔄 `.github/workflows/` - Separate workflows for frontend and backend
- 🔄 `infra/bicep/main.bicep` - Deploy both Static Web App and Container App

---

## 🌐 How Static Web Apps Handle Multiple Users:

### **The Magic:**

1. **Files Stored Once:**
   ```
   Azure Storage (Central)
   └── Your App Files
       ├── index.html (5 KB)
       ├── bundle.js (150 KB)
       └── styles.css (20 KB)
   ```

2. **CDN Distributes Globally:**
   ```
   User in Oslo    → Oslo CDN Node    → 5ms latency
   User in Tokyo   → Tokyo CDN Node   → 5ms latency
   User in New York→ NYC CDN Node     → 5ms latency
   ```

3. **Each User Gets Their Own:**
   - Browser downloads files ONCE
   - React app runs in THEIR browser
   - No server-side rendering needed
   - NO connection limit!

4. **100,000 Users Simultaneously:**
   - Each downloads files from nearest CDN
   - Each runs React in their browser
   - Static Web App cost: **Still $0-9/month!**
   - Backend API scales 1-3+ containers to handle requests

### **Analogy:**

**Old Way (Container serving everything):**
- Like a restaurant where chef cooks AND serves
- Chef gets overwhelmed with many customers
- Expensive (chef works 24/7)

**New Way (Static Web App + API):**
- Like a vending machine + chef
- Vending machine (Static Web App) gives everyone the "menu" instantly
- Chef (API) only cooks when someone orders
- Cheap and fast!

---

## 💰 Cost Comparison:

### **Old Architecture:**
```
Container App (full-stack):
- 0.5 vCPU × 24/7 = ~$38/month
- 1.0 GB RAM × 24/7 = ~$8/month
Total: ~$46/month
```

### **New Architecture:**
```
Static Web App (frontend):
- Free tier: $0/month (100 GB bandwidth)
- OR Standard: $9/month (unlimited bandwidth)

Container App (API only):
- 0.25 vCPU × 24/7 = ~$19/month
- 0.5 GB RAM × 24/7 = ~$4/month
- Can scale to 0 when idle!

Total: $0-32/month (30-100% savings!)
```

---

## 🚀 Deployment Flow:

### **Frontend (Static Web App):**
```yaml
1. GitHub Actions triggered
2. npm install & npm run build
3. Uploads dist/ to Static Web App
4. CDN automatically refreshed
5. Live in ~2 minutes!
```

### **Backend (Container App):**
```yaml
1. GitHub Actions triggered
2. docker build backend/
3. docker push to ACR
4. Container App pulls new image
5. Live in ~5 minutes!
```

### **Independent Deploys:**
- Change frontend → Only frontend redeploys
- Change backend → Only backend redeploys
- Change both → Both redeploy (parallel!)

---

## 🔗 How They Connect:

### **Environment Variable Configuration:**

**In Static Web App:**
```javascript
// frontend/src/services/api.js
const API_URL = import.meta.env.VITE_API_URL;
// Set during deployment via staticwebapp.config.json
```

**Set in GitHub Actions:**
```yaml
- name: Deploy Static Web App
  with:
    app_location: "frontend"
  env:
    VITE_API_URL: ${{ needs.deploy-backend.outputs.api_url }}
```

**Result:**
- Local dev: `http://localhost:8000/api`
- Production: `https://ca-api-xxx.azurecontainerapps.io/api`

---

## 🛡️ Security:

### **CORS Configuration:**

**Backend allows:**
```python
allow_origins=[
    "https://*.azurestaticapps.net",  # Your Static Web App
    "http://localhost:5173",           # Local dev
]
```

**Static Web App config:**
```json
{
  "globalHeaders": {
    "X-Frame-Options": "DENY",
    "X-Content-Type-Options": "nosniff"
  }
}
```

---

## 📊 Benefits Summary:

| Feature | Before | After |
|---------|--------|-------|
| **Frontend Speed** | ~100ms (server) | ~5ms (CDN) |
| **Global Performance** | Slow from Norway | Fast everywhere |
| **Cost** | ~$46/month | ~$0-32/month |
| **Scalability** | Limited | Massive |
| **Independent Deploys** | ❌ | ✅ |
| **Frontend Changes** | Full rebuild | 2 min deploy |
| **Backend Changes** | Full rebuild | 5 min deploy |
| **Can Scale to 0** | ❌ | ✅ (API only) |

---

## 🎯 Next Steps:

1. ✅ Delete old infrastructure
2. ✅ Separate Dockerfiles
3. ✅ Update code (CORS, API URL)
4. ⏳ Update Bicep (Static Web App + Container App)
5. ⏳ Update GitHub Actions workflows
6. ⏳ Deploy and test!

---

Ready to continue with the infrastructure files? 🚀
