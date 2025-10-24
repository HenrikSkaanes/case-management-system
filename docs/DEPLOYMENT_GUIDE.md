# Deployment Guide - Choosing Your Architecture

## 🎯 Which Template Should You Use?

### Option 1: Budget POC (~$80-100/month) ⭐ RECOMMENDED FOR POC
**File:** `main.budget.bicep`

**Best for:**
- Initial POC with a few users
- Testing functionality
- Demonstrating core features
- Limited budget (~$80-100/month)

**What you get:**
- ✅ Private VNet with isolated networking
- ✅ Private PostgreSQL (no public access)
- ✅ Key Vault for secrets
- ✅ NAT Gateway (fixed egress IP)
- ✅ Container Apps with managed identity
- ✅ Static Web App (free tier)
- ❌ No API Management
- ❌ No Front Door/WAF

**Deployment command:**
```bash
az deployment group create \
  --resource-group rg-case-management-dev \
  --template-file infra/bicep/main.budget.bicep \
  --parameters postgresqlAdminPassword='YourSecurePassword123!'
```

---

### Option 2: Full Production (~$350-450/month)
**File:** `main.bicep`

**Best for:**
- Production deployments
- Multi-user applications
- Compliance requirements
- Need for rate limiting, WAF, DDoS protection

**What you get:**
- ✅ Everything from Budget POC
- ✅ API Management (rate limiting, analytics)
- ✅ Front Door Premium (global CDN, WAF, DDoS)
- ✅ Advanced security policies

**Deployment command:**
```bash
az deployment group create \
  --resource-group rg-case-management-dev \
  --template-file infra/bicep/main.bicep \
  --parameters postgresqlAdminPassword='YourSecurePassword123!'
```

---

## ⚠️ Impact on Existing Resources

### What Happens When You Deploy

#### **Resources That Will Be DELETED & RECREATED:**

1. **Container App Environment** (`cae-casemanagement-dev`)
   - Why: Needs VNet injection (can't be added after creation)
   - Impact: ~5 minutes downtime
   - Data loss: None (stateless)

2. **Container App** (`ca-api-casemanagement-dev`)
   - Why: New environment requires new app
   - Impact: Recreated automatically
   - Data loss: None (stateless)

3. **PostgreSQL Server** (`psql-casemanagement-dev`)
   - Why: Moving from public to private (different resource type)
   - Impact: **⚠️ DATABASE BACKUP REQUIRED**
   - Data loss: **YES - if not backed up**

#### **Resources That Will Be KEPT:**

- ✅ **Log Analytics** - No changes
- ✅ **ACR** - No changes
- ✅ **Static Web App** - Minor config update only

#### **New Resources:**

- ➕ VNet + Subnets
- ➕ NAT Gateway (budget version) or + APIM + Front Door (full version)
- ➕ Key Vault
- ➕ Private DNS Zone

---

## 🗄️ CRITICAL: Database Migration Steps

### Before Deployment

**⚠️ BACKUP YOUR DATA FIRST!**

```bash
# 1. Get current PostgreSQL connection details
az postgres flexible-server show \
  --resource-group rg-case-management-dev \
  --name psql-casemanagement-dev

# 2. Backup your database
pg_dump -h psql-casemanagement-dev.postgres.database.azure.com \
  -U caseadmin \
  -d casemanagement \
  -f backup_$(date +%Y%m%d_%H%M%S).sql

# 3. Alternatively, use Azure backup
az postgres flexible-server backup create \
  --resource-group rg-case-management-dev \
  --name psql-casemanagement-dev \
  --backup-name pre-migration-backup
```

### After Deployment

```bash
# 1. Get new private PostgreSQL connection
NEW_DB_HOST=$(az deployment group show \
  --resource-group rg-case-management-dev \
  --name budget-deployment \
  --query properties.outputs.postgresqlServerFqdn.value -o tsv)

# 2. Restore from backup (requires VM in same VNet or VPN)
psql -h $NEW_DB_HOST \
  -U caseadmin \
  -d casemanagement \
  -f backup_*.sql
```

---

## 🚀 Step-by-Step Deployment

### Step 1: Backup Existing Data

```bash
# Export current database
pg_dump -h psql-casemanagement-dev.postgres.database.azure.com \
  -U caseadmin \
  -d casemanagement \
  -f backup_$(date +%Y%m%d_%H%M%S).sql
```

### Step 2: Review Changes with What-If

```bash
# For budget version
az deployment group what-if \
  --resource-group rg-case-management-dev \
  --template-file infra/bicep/main.budget.bicep \
  --parameters postgresqlAdminPassword='YourSecurePassword123!'

# Look for:
# - Green (+): New resources
# - Yellow (~): Modified resources
# - Red (-): Deleted resources
```

### Step 3: Deploy Budget Version (Recommended)

```bash
az deployment group create \
  --resource-group rg-case-management-dev \
  --template-file infra/bicep/main.budget.bicep \
  --parameters postgresqlAdminPassword='YourSecurePassword123!' \
  --name budget-deployment
```

### Step 4: Restore Database

```bash
# Get new connection details
az deployment group show \
  --resource-group rg-case-management-dev \
  --name budget-deployment \
  --query properties.outputs

# Note: New PostgreSQL is private - you'll need:
# Option A: Deploy from Azure Cloud Shell (in Azure network)
# Option B: Create jump box VM in the VNet
# Option C: Set up Azure Bastion or VPN
```

### Step 5: Update Container App with Real Image

```bash
# Build and push your image
az acr build --registry acrcasemanagementdev \
  --image api:latest \
  backend/

# Container App will auto-detect new image
```

### Step 6: Get Static Web App Deployment Token

```bash
az staticwebapp secrets list \
  --name stapp-casemanagement-dev \
  --resource-group rg-case-management-dev \
  --query properties.apiKey -o tsv
```

---

## 💡 Alternative: Gradual Migration

If you want to minimize risk, deploy to a NEW resource group first:

```bash
# 1. Create new resource group
az group create \
  --name rg-case-management-dev-v2 \
  --location norwayeast

# 2. Deploy to new RG
az deployment group create \
  --resource-group rg-case-management-dev-v2 \
  --template-file infra/bicep/main.budget.bicep \
  --parameters postgresqlAdminPassword='YourSecurePassword123!'

# 3. Test thoroughly
# 4. Migrate data
# 5. Switch DNS/traffic
# 6. Delete old resource group when confident
```

---

## 📊 Cost Comparison

| Item | Current | Budget POC | Full Production |
|------|---------|-----------|----------------|
| Monthly Cost | $50-75 | $80-100 | $350-450 |
| Private Network | ❌ | ✅ | ✅ |
| NAT Gateway | ❌ | ✅ | ✅ |
| Key Vault | ❌ | ✅ | ✅ |
| APIM | ❌ | ❌ | ✅ |
| Front Door/WAF | ❌ | ❌ | ✅ |

---

## 🎯 Recommendation

**For POC with a few users:**
1. Use `main.budget.bicep` (~$80-100/month)
2. Deploy to new resource group first (safest)
3. Test thoroughly
4. Migrate when confident

**Additional cost savings:**
- Set `deployNatGateway: false` to save ~$30/month (loses fixed IP)
- Use PostgreSQL `Standard_B1s` instead of `B1ms` to save ~$13/month

**Upgrade later:**
- When POC is successful and you need production features
- Switch to `main.bicep` with APIM + Front Door
- Incremental cost: +$270-350/month
