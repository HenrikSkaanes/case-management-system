# 🔧 Backend API Issue - Root Cause Analysis & Fix

**Date**: October 28, 2025  
**Issue**: Backend API not working correctly - Kanban board Employee Portal not loading  
**Status**: ✅ **ROOT CAUSE IDENTIFIED AND FIXED**

---

## 🔍 What Was Wrong?

### Problem Discovery

1. **Container App Using Wrong Image**:
   ```
   Current Image: mcr.microsoft.com/azuredocs/containerapps-helloworld:latest
   Expected Image: acrcasemanagementdev.azurecr.io/api:<commit-sha>
   ```

2. **Symptoms**:
   - Frontend couldn't open Employee Portal page
   - Kanban board not loading
   - Container App showing "Hello World" instead of FastAPI backend
   - API endpoints not responding correctly

3. **Root Cause in main.bicep Line 205**:
   ```bicep
   containerImage: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'  // Placeholder
   ```
   
   This was a **hardcoded placeholder image** that was never updated to use your actual API image from ACR!

---

## 🛠️ Fixes Applied

### 1. ✅ Fixed Container Image Reference

**File**: `infra/bicep/main.bicep` Line 205

**Before**:
```bicep
containerImage: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'  // Placeholder
containerRegistryServer: acr.outputs.acrLoginServer
containerRegistryUsername: ''
containerRegistryPassword: ''
```

**After**:
```bicep
containerImage: '${acr.outputs.acrLoginServer}/api:${imageTag}'
containerRegistryServer: acr.outputs.acrLoginServer
containerRegistryUsername: ''
containerRegistryPassword: ''  // Using Managed Identity for ACR pull
```

**What This Does**:
- Uses dynamic ACR login server (acrcasemanagementdev.azurecr.io)
- References your actual `api` image
- Uses `imageTag` parameter (defaults to 'latest', or use commit SHA)

### 2. ✅ Added ACR Pull Role Assignment

**File**: `infra/bicep/main.bicep` (new resource after line 220)

```bicep
// 6a. Grant Container App Managed Identity permission to pull from ACR
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrName, apiAppName, 'AcrPull')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull role
    principalId: containerAppsEnv.outputs.managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}
```

**What This Does**:
- Grants Container App's Managed Identity the `AcrPull` role
- Allows Container App to pull images from ACR without username/password
- More secure than using ACR admin credentials

### 3. ✅ Verified Backend Deployment Workflow

**File**: `.github/workflows/deploy-backend.yml`

**Key Steps Confirmed**:
1. ✅ Builds Docker image with two tags:
   - `api:<commit-sha>` (specific version)
   - `api:latest` (latest version)
2. ✅ Pushes to ACR
3. ✅ Configures ACR access with Managed Identity
4. ✅ Updates Container App with new image
5. ✅ Uses `github.sha` to ensure specific version deployment

**This workflow is CORRECT** - no changes needed!

---

## 🔍 Why Was Container App Using Old Image?

### Timeline of Events:

1. **Initial Deployment** (via `main.bicep`):
   - Deployed Container App with placeholder "Hello World" image
   - This is what's currently running

2. **Backend Code Changes**:
   - You made changes to FastAPI backend
   - Backend workflow built new images: `api:556e5f4`, `api:c90d525`, `api:8c2492f`
   - Pushed to ACR successfully

3. **The Problem**:
   - Infrastructure deployment (`main.bicep`) **never updated** to use real API image
   - Backend workflow correctly updates Container App AFTER deployment
   - But if infrastructure re-deploys, it **overwrites** with placeholder image!

### Current State:

```bash
# Container App Status
Image: mcr.microsoft.com/azuredocs/containerapps-helloworld:latest ❌
Status: Running
Provisioning: InProgress (likely from failed deployment)

# Available Images in ACR
acrcasemanagementdev.azurecr.io/api:556e5f43ae85f3e342c1e7a264dff2f6bf1bf5f4 ✅
acrcasemanagementdev.azurecr.io/api:c90d525f472259892b2fc53009fa349a6e3347ba ✅
acrcasemanagementdev.azurecr.io/api:8c2492f32d0d59c09f492f1dcc1ac1706a4185de ✅
```

---

## 🚀 How to Fix Your Deployment

### Option 1: Re-deploy Infrastructure (Recommended)

This will fix the infrastructure code and use the correct image:

```powershell
# 1. Commit and push the fixes (I'll do this)
git add infra/bicep/main.bicep
git commit -m "Fix: Use actual API image from ACR instead of placeholder"
git push origin main

# 2. Manually trigger infrastructure workflow on GitHub
# Go to: https://github.com/HenrikSkaanes/case-management-system/actions
# Click "Deploy Cost-Optimized Infrastructure"
# Click "Run workflow" → Select "dev" → Run

# 3. After infra succeeds, trigger backend workflow
# Go to: https://github.com/HenrikSkaanes/case-management-system/actions
# Click "Deploy Backend API"
# Click "Run workflow" → Run
```

### Option 2: Quick Fix - Update Container App Directly

If you want immediate fix without re-deploying infrastructure:

```powershell
# Update Container App to use latest API image
az containerapp update \
  --name ca-api-casemanagement-dev \
  --resource-group rg-case-management-dev \
  --image acrcasemanagementdev.azurecr.io/api:latest

# Or use specific commit SHA (most recent)
az containerapp update \
  --name ca-api-casemanagement-dev \
  --resource-group rg-case-management-dev \
  --image acrcasemanagementdev.azurecr.io/api:8c2492f32d0d59c09f492f1dcc1ac1706a4185de
```

**WARNING**: If you re-deploy infrastructure later, it will revert to placeholder unless you merge the fixes!

---

## ✅ Verification Steps

After deployment, verify the fix:

### 1. Check Container App Image

```powershell
az containerapp show \
  --name ca-api-casemanagement-dev \
  --resource-group rg-case-management-dev \
  --query "properties.template.containers[0].image" -o tsv

# Expected: acrcasemanagementdev.azurecr.io/api:<sha or latest>
# NOT: mcr.microsoft.com/azuredocs/containerapps-helloworld:latest
```

### 2. Test API Health Endpoint

```powershell
curl https://ca-api-casemanagement-dev.wonderfulfield-b342f39f.norwayeast.azurecontainerapps.io/health

# Expected Response:
# {"status":"ok"}
```

### 3. Test API Root Endpoint

```powershell
curl https://ca-api-casemanagement-dev.wonderfulfield-b342f39f.norwayeast.azurecontainerapps.io/

# Expected Response:
# {
#   "message": "Case Management API",
#   "version": "2.1.0",
#   "status": "running",
#   "docs": "/docs",
#   "redoc": "/redoc"
# }
```

### 4. Test Kanban Board from Frontend

1. Open your Static Web App: https://zealous-hill-04965a603.3.azurestaticapps.net
2. Click "Employee Portal"
3. Kanban board should load with tickets
4. Try creating/moving tickets

---

## 🔧 Configuration Details

### Backend Configuration (Correct)

| Setting | Value | Status |
|---------|-------|--------|
| **Port** | 8000 | ✅ Correct |
| **Dockerfile EXPOSE** | 8000 | ✅ Correct |
| **Container App targetPort** | 8000 | ✅ Correct |
| **FastAPI uvicorn --port** | 8000 | ✅ Correct |
| **Health endpoint** | /health | ✅ Correct |
| **CORS origins** | Static Web App URL | ✅ Correct |

### Container Registry Configuration

| Setting | Value | Status |
|---------|-------|--------|
| **ACR Name** | acrcasemanagementdev | ✅ Exists |
| **ACR Login Server** | acrcasemanagementdev.azurecr.io | ✅ Correct |
| **Image Repository** | api | ✅ Exists |
| **Available Tags** | 3 commit SHAs | ✅ Available |
| **Managed Identity** | System-assigned | ✅ Configured |
| **AcrPull Role** | Will be assigned on re-deploy | ⏳ Pending |

---

## 📋 Summary

### What We Found:

1. ❌ Container App using Microsoft's "Hello World" placeholder image
2. ❌ Infrastructure code hardcoded with placeholder, never updated
3. ❌ Missing ACR Pull role assignment for Managed Identity
4. ✅ Backend workflow is correct and working
5. ✅ Your API images exist in ACR and are ready to use
6. ✅ Port configuration (8000) is correct everywhere

### What We Fixed:

1. ✅ Updated `main.bicep` to use actual API image from ACR
2. ✅ Added dynamic image reference: `${acr.outputs.acrLoginServer}/api:${imageTag}`
3. ✅ Added ACR Pull role assignment for Container App Managed Identity
4. ✅ Prepared infrastructure for proper deployment

### Next Steps:

**Immediate** (Choose One):
- **Option A**: Manually update Container App image (quick fix)
- **Option B**: Re-deploy infrastructure (proper fix) ← **RECOMMENDED**

**After Fix**:
1. Test API health endpoint
2. Test frontend Employee Portal
3. Verify Kanban board loads
4. Create/move tickets to test functionality

---

## 💡 Lessons Learned

### Why This Happened:

1. **Placeholder Not Replaced**: Initial infrastructure used placeholder image for quick deployment
2. **Decoupled Deployments**: Infrastructure and backend deployments are separate
3. **No Image Validation**: No check to ensure Container App is using actual API image

### Prevent Future Issues:

1. ✅ **Use Dynamic Image References**: Always reference ACR dynamically
2. ✅ **Managed Identity**: Use Managed Identity instead of credentials
3. ✅ **Deployment Order**: Infrastructure → Backend → Frontend
4. ✅ **Health Checks**: Monitor /health endpoint
5. ✅ **Add Monitoring**: Deploy monitoring module to catch issues early (we created this!)

---

## 🎯 Ready to Deploy?

**Say "yes, commit and push" and I'll**:
1. Commit the main.bicep fix
2. Push to GitHub
3. Provide deployment commands

Or say **"quick fix first"** and I'll give you the manual update command to fix it immediately while we prepare the proper infrastructure deployment.
