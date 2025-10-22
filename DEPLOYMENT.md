# 🚀 Deployment Guide

## Prerequisites Completed ✅

- [x] GitHub repository created
- [x] Code pushed to GitHub
- [x] Bicep infrastructure files created
- [x] GitHub Actions workflow created
- [x] Azure Service Principal created

## 🔐 Setup GitHub Secrets

### Required Secret: AZURE_CREDENTIALS

The Service Principal has been created. **Copy the JSON output from the terminal** and add it to GitHub:

1. Go to: https://github.com/HenrikSkaanes/case-management-system/settings/secrets/actions

2. Click **"New repository secret"**

3. **Name:** `AZURE_CREDENTIALS`

4. **Value:** Paste the entire JSON (from `{` to `}`)

5. Click **"Add secret"**

---

## 🎯 How the CI/CD Pipeline Works

```
┌─────────────────────────────────────────────────────────────┐
│  You: git push to main branch                              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  GitHub Actions: Triggered automatically                    │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
┌──────────────────┐    ┌──────────────────┐
│  Job 1: Deploy   │    │  (Parallel if    │
│  Infrastructure  │    │  already exists) │
│                  │    │                  │
│  - Login Azure   │    │                  │
│  - Run Bicep     │    │                  │
│  - Create ACR    │    │                  │
│  - Create App    │    │                  │
└────────┬─────────┘    └──────────────────┘
         │
         ▼
┌──────────────────┐
│  Job 2: Build    │
│  & Push Image    │
│                  │
│  - docker build  │
│  - docker push   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Job 3: Deploy   │
│  Container App   │
│                  │
│  - Update app    │
│  - Get URL       │
└────────┬─────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│  🎉 Your app is live!                                       │
│  GitHub Actions shows you the URL in the summary           │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 What Happens on First Deployment

1. **Infrastructure Creation** (~5-10 minutes)
   - Resource Group: `rg-case-management-dev`
   - Container Registry: `acrcasemanagementdev`
   - Log Analytics: `log-casemanagement-dev`
   - Container App Environment: `cae-casemanagement-dev`
   - Container App: `ca-casemanagement-dev`

2. **Docker Build & Push** (~3-5 minutes)
   - Builds multi-stage Dockerfile
   - Pushes image to ACR
   - Tags with git commit SHA + "latest"

3. **Application Deployment** (~2-3 minutes)
   - Container App pulls image from ACR
   - Starts your application
   - Exposes on HTTPS URL

**Total time: ~10-18 minutes** (subsequent deploys are faster)

---

## 🧪 Test the Pipeline

After adding the GitHub secret:

1. **Make a small change** to trigger the pipeline:
   ```bash
   cd "/Users/henrik/Desktop/Azure/Container Playground/case-management-system"
   
   # Add all new files
   git add .
   
   # Commit
   git commit -m "Add Bicep infrastructure and CI/CD pipeline"
   
   # Push to trigger deployment
   git push
   ```

2. **Watch the deployment:**
   - Go to: https://github.com/HenrikSkaanes/case-management-system/actions
   - Click on the running workflow
   - Watch the jobs execute

3. **Get your app URL:**
   - At the bottom of the workflow run, you'll see a deployment summary
   - Copy the application URL
   - Open it in your browser!

---

## 📊 Monitor Your Application

### Azure Portal
1. Go to: https://portal.azure.com
2. Search for "ca-casemanagement-dev"
3. View:
   - **Logs:** See application logs
   - **Metrics:** CPU, memory, requests
   - **Revisions:** Deployment history

### GitHub Actions
- Every deployment creates a summary with:
  - Application URL
  - Docker image tag
  - Deployment timestamp

---

## 🔧 Making Changes

### Frontend Changes
```bash
# Edit files in frontend/src/
vim frontend/src/App.jsx

# Commit and push
git add .
git commit -m "Update: Changed layout"
git push

# GitHub Actions automatically deploys!
```

### Backend Changes
```bash
# Edit files in backend/app/
vim backend/app/main.py

# Commit and push
git add .
git commit -m "Feature: Add new API endpoint"
git push
```

### Infrastructure Changes
```bash
# Edit Bicep files
vim infra/bicep/main.bicep

# Commit and push
git add .
git commit -m "Infrastructure: Increase CPU to 1.0"
git push
```

**Every push to `main` automatically deploys everything!**

---

## 💰 Cost Management

### Monitor Spending
```bash
# View current month's cost
az consumption usage list --start-date 2025-10-01 -o table
```

### Scale Down When Not Using
```bash
# Scale to 0 replicas (saves money)
az containerapp update \
  --name ca-casemanagement-dev \
  --resource-group rg-case-management-dev \
  --min-replicas 0

# Scale back up
az containerapp update \
  --name ca-casemanagement-dev \
  --resource-group rg-case-management-dev \
  --min-replicas 1
```

### Delete Everything
```bash
# Delete entire resource group (stops all costs)
az group delete --name rg-case-management-dev --yes
```

---

## 🐛 Troubleshooting

### Deployment Failed
1. Check GitHub Actions logs
2. Look for red X marks
3. Click on failed step to see error

### App Not Loading
```bash
# Check app status
az containerapp show \
  --name ca-casemanagement-dev \
  --resource-group rg-case-management-dev \
  --query properties.runningStatus

# View logs
az containerapp logs show \
  --name ca-casemanagement-dev \
  --resource-group rg-case-management-dev \
  --follow
```

### Can't Access URL
- Wait 2-3 minutes after deployment
- Check if HTTPS (not HTTP)
- Verify firewall/VPN not blocking

---

## 🎓 What You've Learned

✅ **Infrastructure as Code** - Define infrastructure in code (Bicep)
✅ **CI/CD Pipelines** - Automated build and deployment (GitHub Actions)
✅ **Containerization** - Package apps in Docker containers
✅ **Cloud Deployment** - Deploy to Azure Container Apps
✅ **GitOps** - Git push triggers automatic deployment
✅ **Modular Architecture** - Separate concerns (modules, jobs)

---

## 🚀 Next Steps

1. Add the GitHub secret
2. Push the code
3. Watch it deploy!
4. Share your live URL!

**Ready? Let's push this code!** 🎉
