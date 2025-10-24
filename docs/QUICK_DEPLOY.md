# Quick Deployment Guide - Cost-Optimized Architecture

## 🎯 You're Deploying

**Architecture:** Full production features with cost-optimized SKUs
**Monthly Cost:** ~$120-150
**Features:**
- ✅ API Management (Consumption tier)
- ✅ Front Door (Standard - CDN without WAF)
- ✅ VNet + Private PostgreSQL
- ✅ Key Vault + Managed Identities
- ✅ NAT Gateway (fixed IP)

---

## ⚠️ IMPORTANT: Backup First!

```bash
# Backup your current database
pg_dump -h psql-casemanagement-dev.postgres.database.azure.com \
  -U caseadmin \
  -d casemanagement \
  -f backup_$(date +%Y%m%d_%H%M%S).sql
```

---

## 🚀 Deployment Commands

### Option 1: Test First with What-If (Recommended)

```bash
cd "/Users/henrik/Desktop/Azure/Container Playground/case-management-system"

# See what will change WITHOUT deploying
az deployment group what-if \
  --resource-group rg-case-management-dev \
  --template-file infra/bicep/main.bicep \
  --parameters @infra/bicep/main.parameters.dev-optimized.json \
  --parameters postgresqlAdminPassword='YourSecurePassword123!'
```

**Review the output:**
- Green `+` = New resources
- Yellow `~` = Modified resources  
- Red `−` = Deleted resources

---

### Option 2: Deploy to Production (After What-If)

```bash
# Deploy the cost-optimized architecture
az deployment group create \
  --resource-group rg-case-management-dev \
  --template-file infra/bicep/main.bicep \
  --parameters @infra/bicep/main.parameters.dev-optimized.json \
  --parameters postgresqlAdminPassword='YourSecurePassword123!' \
  --name optimized-deployment
```

**Deployment time:** ~15-20 minutes

---

### Option 3: Deploy to New Resource Group (Safest)

```bash
# Create new resource group
az group create \
  --name rg-case-management-dev-v2 \
  --location norwayeast

# Deploy to new RG
az deployment group create \
  --resource-group rg-case-management-dev-v2 \
  --template-file infra/bicep/main.bicep \
  --parameters @infra/bicep/main.parameters.dev-optimized.json \
  --parameters postgresqlAdminPassword='YourSecurePassword123!' \
  --name optimized-deployment

# Test thoroughly, then migrate traffic
# Delete old RG when confident
```

---

## 📝 What Gets Deployed

### New Resources (Will be created)
- VNet with 3 subnets
- NAT Gateway + Public IP
- Key Vault
- Private DNS Zone (PostgreSQL)
- **API Management (Consumption tier)**
- **Front Door (Standard tier)**

### Replaced Resources (Old deleted, new created)
- Container App Environment (needs VNet injection)
- Container App (part of new environment)
- PostgreSQL (public → private)

### Kept Resources (No changes)
- Log Analytics ✅
- Container Registry ✅
- Static Web App ✅ (config update only)

---

## 🔍 Post-Deployment Steps

### 1. Get Deployment Outputs

```bash
az deployment group show \
  --resource-group rg-case-management-dev \
  --name optimized-deployment \
  --query properties.outputs
```

### 2. Note Important URLs

```bash
# Frontend URL (Front Door)
FRONTEND_URL=$(az deployment group show \
  --resource-group rg-case-management-dev \
  --name optimized-deployment \
  --query properties.outputs.frontDoorUrl.value -o tsv)

echo "Access your app at: $FRONTEND_URL"

# API Management URL
APIM_URL=$(az deployment group show \
  --resource-group rg-case-management-dev \
  --name optimized-deployment \
  --query properties.outputs.apimUrl.value -o tsv)

echo "API Gateway: $APIM_URL"
```

### 3. Restore Database (if needed)

```bash
# Get new PostgreSQL hostname
NEW_DB_HOST=$(az deployment group show \
  --resource-group rg-case-management-dev \
  --name optimized-deployment \
  --query properties.outputs.postgresqlServerFqdn.value -o tsv)

# Note: New PostgreSQL is private - you'll need to restore from:
# - Azure Cloud Shell (in Azure network)
# - VM in the VNet
# - Azure Bastion or VPN connection
```

### 4. Update Static Web App Config

The Static Web App now points to APIM instead of Container App directly:

```bash
# Get Static Web App deployment token
az staticwebapp secrets list \
  --name stapp-casemanagement-dev \
  --resource-group rg-case-management-dev \
  --query properties.apiKey -o tsv
```

Use this token in your GitHub Actions workflow.

### 5. Deploy Backend Image

```bash
# Build and push to ACR
az acr build \
  --registry acrcasemanagementdev \
  --image api:latest \
  backend/

# Container App will auto-update with new image
```

---

## 💰 Cost Monitoring

### Set Up Budget Alert

```bash
# Create a budget for $150/month
az consumption budget create \
  --resource-group rg-case-management-dev \
  --budget-name case-management-budget \
  --amount 150 \
  --time-grain Monthly \
  --start-date $(date +%Y-%m-01) \
  --end-date 2026-12-31 \
  --notification-enabled true \
  --notification-threshold 80 \
  --contact-emails your-email@example.com
```

### View Current Costs

```bash
# See current month costs
az consumption usage list \
  --resource-group rg-case-management-dev \
  --start-date $(date -v1d +%Y-%m-01) \
  --end-date $(date +%Y-%m-%d)
```

---

## 🎓 Learning Resources

After deployment, explore these in Azure Portal:

### API Management
1. Go to: APIM → APIs → case-api
2. Try: Test console
3. View: Analytics → Response times
4. Edit: Policies → Add rate limiting
5. Learn: [APIM Policies](https://learn.microsoft.com/en-us/azure/api-management/api-management-policies)

### Front Door
1. Go to: Front Door → Endpoints
2. View: Origins & Origin groups
3. Test: Different routes (/, /api/*)
4. Monitor: Metrics → Request count
5. Learn: [Front Door routing](https://learn.microsoft.com/en-us/azure/frontdoor/front-door-routing-architecture)

### Container Apps
1. Go to: Container App → Monitoring
2. View: Log stream (real-time logs)
3. Check: Metrics → CPU, Memory, Requests
4. Scale: Revision management → Scale rules

---

## 🔧 Troubleshooting

### APIM Cold Starts
**Issue:** First request takes ~10 seconds
**Solution:** Normal for Consumption tier. Subsequent requests are fast.

### Front Door Cache
**Issue:** API changes not reflected immediately
**Solution:** Front Door caches responses. API route has caching disabled, but may take 1-2 minutes.

### Private PostgreSQL Access
**Issue:** Can't connect from local machine
**Solution:** Database is private. Use:
- Azure Cloud Shell
- Jump box VM in VNet
- Azure Bastion

### Container App Not Starting
**Issue:** App shows as not ready
**Solution:**
1. Check logs: Container App → Log stream
2. Verify image exists in ACR
3. Check environment variables
4. Ensure managed identity has DB access

---

## 📊 Success Criteria

After deployment, verify:

- [ ] Front Door URL loads the frontend
- [ ] API Management URL returns API response
- [ ] Container App scales up on traffic
- [ ] PostgreSQL is accessible (from VNet)
- [ ] Key Vault has secrets
- [ ] Costs are under $150/month
- [ ] All services show "Healthy" in portal

---

## 🎯 Next Steps

1. **Deploy** using commands above
2. **Monitor** costs in Azure Portal
3. **Learn** by exploring APIM policies
4. **Experiment** with Front Door routing
5. **Document** what you learn

Ready to deploy? Start with `what-if` command! 🚀
