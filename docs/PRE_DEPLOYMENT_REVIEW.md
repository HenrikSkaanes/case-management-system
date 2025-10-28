# 🔍 PRE-DEPLOYMENT REVIEW: Monitoring Setup

**Date**: October 28, 2025  
**Reviewer**: AI Assistant  
**Status**: ⚠️ **DO NOT DEPLOY YET - CRITICAL ISSUES FOUND**

---

## ❌ CRITICAL ISSUES (Must Fix Before Deployment)

### 1. **Missing Module Integration in main.bicep**

**Problem**: The monitoring module is created but NOT integrated into `main.bicep`

**Impact**: Monitoring won't be deployed at all

**Fix Required**:
```bicep
// Add to main.bicep after module #11 (postgresqlAadConfig)

// 12. Monitoring & Alerts (Based on AMBA recommendations)
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring-deployment'
  params: {
    baseName: baseName
    environmentName: environmentName
    location: location
    logAnalyticsWorkspaceId: logs.outputs.logAnalyticsId
    containerAppId: containerAppsEnv.outputs.containerAppResourceId  // ⚠️ NEEDS NEW OUTPUT
    postgresqlServerId: postgresqlPrivate.outputs.serverResourceId    // ⚠️ NEEDS NEW OUTPUT
    apimId: apiManagement.outputs.apimId                              // ✅ EXISTS
    alertEmails: [
      'your-email@example.com'  // ⚠️ UPDATE THIS!
    ]
    tags: tags
  }
  dependsOn: [
    containerAppsEnv
    postgresqlPrivate
    apiManagement
    logs
  ]
}
```

### 2. **Missing Required Outputs in Existing Modules**

**Problem**: Monitoring needs full resource IDs, but modules only export names

**Modules Needing Updates**:

#### A. `modules/containerapps-env-vnet.bicep`
**Current Output**: Missing `containerAppResourceId`
```bicep
// ADD THIS OUTPUT (after line ~230)
output containerAppResourceId string = containerApp.id
```

#### B. `modules/postgres-private.bicep`
**Current Output**: Missing `serverResourceId`
```bicep
// ADD THIS OUTPUT (after line ~155)
output serverResourceId string = postgresqlServer.id
```

#### C. `modules/apim.bicep`
**Current Output**: ✅ Already has `apimId` - NO CHANGE NEEDED

### 3. **Email Configuration Required**

**Problem**: `alertEmails` parameter is empty array by default

**Impact**: You won't receive any alerts!

**Fix Required**:
- Update `main.bicep` or parameter file with real email addresses
- OR add parameter to `main.parameters.dev-optimized.json`:

```json
{
  "alertEmails": {
    "value": [
      "henrik@example.com",
      "team@example.com"
    ]
  }
}
```

---

## ⚠️ WARNINGS (Should Review)

### 1. **Log Query May Fail Initially**

**Issue**: The log alert queries `ContainerAppConsoleLogs_CL` table which may not exist until Container App sends logs

**Impact**: Log-based alert will fail for first ~15 minutes after deployment

**Mitigation**: This is expected behavior. Alert will auto-enable once logs start flowing.

**Fix** (Optional - Disable until logs exist):
```bicep
// In monitoring.bicep, line ~410
enabled: false  // Change to false initially, enable manually later
```

### 2. **Alert Thresholds May Need Tuning**

**Current Thresholds** (from AMBA):
- CPU: 90%
- Memory: 90%
- Restarts: >3 in 15min
- Errors: >5 in 15min

**Recommendation**: 
- Keep defaults for first week
- Tune based on actual usage patterns
- Document in runbook

### 3. **Activity Log Alerts Scope**

**Issue**: Activity log alerts are scoped to entire resource group

**Impact**: Will alert on ANY resource deletion/security change in RG

**Consider**: 
- Keep as-is for comprehensive monitoring
- OR narrow scope to specific resources

---

## ✅ THINGS THAT LOOK GOOD

### 1. **Alert Configuration**
- ✅ Uses AMBA recommended thresholds
- ✅ Proper severity levels (1=Critical, 2=Warning)
- ✅ Appropriate evaluation windows (5-15 minutes)
- ✅ Correct resource types specified

### 2. **Action Groups**
- ✅ Separate critical and warning groups
- ✅ Uses common alert schema (better formatting)
- ✅ Extensible (can add SMS, webhooks later)

### 3. **Alert Coverage**
- ✅ Container App: CPU, Memory, Restarts, 5xx errors
- ✅ PostgreSQL: CPU, Memory, Storage, Connections
- ✅ APIM: Latency, Failures
- ✅ Logs: Application errors
- ✅ Activity: Deletions, Security changes

### 4. **Module Structure**
- ✅ Well-organized and commented
- ✅ Uses descriptive resource names
- ✅ Proper dependencies
- ✅ Comprehensive outputs

---

## 🚀 DEPLOYMENT CHECKLIST

Before running the workflow, complete these steps:

### Step 1: Fix Missing Outputs ✅ I'LL DO THIS

- [ ] Add `containerAppResourceId` output to `modules/containerapps-env-vnet.bicep`
- [ ] Add `serverResourceId` output to `modules/postgres-private.bicep`

### Step 2: Integrate Monitoring Module ✅ I'LL DO THIS

- [ ] Add monitoring module call to `main.bicep`
- [ ] Add outputs to expose monitoring resources

### Step 3: Configure Email Alerts ⚠️ YOU MUST DO THIS

- [ ] Update email addresses in parameter file OR
- [ ] Add emails directly in main.bicep module call

### Step 4: Optional Improvements (Can Do Later)

- [ ] Add SMS receivers to action groups
- [ ] Set up Teams/Slack webhooks
- [ ] Create workbook for visualization
- [ ] Add Grafana (if budget allows $240/month)

---

## 📊 ABOUT GRAFANA DASHBOARDS

### Question: "Can I set up Grafana dashboard after deployment, or is it ready out of the box?"

**Answer**: 

#### Option 1: Azure Managed Grafana (Recommended)

**NOT included in current deployment** - Would need to add separately.

**How to Add**:
1. Deploy Azure Managed Grafana instance (~$240/month)
2. Connect to Log Analytics workspace
3. Import community dashboards OR create custom ones

**Out of the Box Experience**:
- ✅ Pre-configured Azure data sources (auto-connects to Log Analytics)
- ✅ Azure AD authentication (automatic SSO)
- ✅ Access to 1000+ community dashboards
- ❌ NOT ready with dashboards - you need to import/create them
- ⏱️ Setup time: 30 minutes after deployment

**Steps to Get Dashboards**:
1. Deploy Grafana (I can add the module)
2. Login via Azure AD
3. Go to Dashboards → Import
4. Use these IDs:
   - **15474**: Azure Monitor Dashboard (comprehensive)
   - **13473**: PostgreSQL Monitoring
   - **11159**: Container Apps

#### Option 2: Azure Workbooks (FREE - Recommended to Start)

**CAN be set up after deployment** - Completely separate from infrastructure.

**How to Add**:
1. Go to Azure Portal → Monitor → Workbooks
2. Click "New" → "Advanced Editor"
3. Paste JSON template (in `docs/WORKBOOK_GUIDE.md`)
4. Save and share with team

**Out of the Box Experience**:
- ✅ FREE
- ✅ No deployment needed
- ✅ Sample template provided in docs
- ✅ Can start using immediately after main deployment
- ⏱️ Setup time: 15 minutes

#### Option 3: Azure Dashboards (Simplest, FREE)

**Can be set up anytime** - Just pin metrics to dashboard.

**How to Add**:
1. Go to Azure Portal → Dashboard
2. Click "New Dashboard"
3. Drag metric tiles from your resources
4. Save

**Out of the Box Experience**:
- ✅ FREE
- ✅ Super simple
- ❌ Limited customization
- ⏱️ Setup time: 5 minutes

### My Recommendation:

**Deployment Phase** (Today):
1. ✅ Deploy monitoring alerts (what we're reviewing)
2. ⏭️ Skip Grafana for now

**Week 1** (After Deployment):
1. ✅ Create Azure Workbook (FREE, powerful)
2. ✅ Set up basic dashboard for management

**Month 2-3** (When Budget Allows):
1. ⏭️ Consider Azure Managed Grafana if you want professional-grade dashboards
2. ✅ Import community dashboards (5 minutes)

---

## 💰 COST ANALYSIS

### With Current Setup (Alerts Only)
- **Month 1**: ~$0-5 (within free tier)
- **Month 2+**: ~$80-100 (after free tier, depends on log volume)

### If Adding Grafana
- **Additional**: ~$240/month (Essential tier)
- **Total**: ~$320-340/month

### Cost Optimization Tips
1. Keep log retention at 30 days (not 90)
2. Use log-based metrics instead of custom metrics
3. Start with Workbooks (FREE) before committing to Grafana

---

## 🎯 DEPLOYMENT STRATEGY

### Recommended Approach:

**Phase 1: Core Monitoring (Today)**
```bash
# 1. I'll fix the code issues
# 2. You update email addresses  
# 3. Deploy monitoring with main infrastructure
az deployment group create \
  --template-file infra/bicep/main.bicep \
  --parameters @infra/bicep/main.parameters.dev-optimized.json
```

**Phase 2: Dashboards (Week 1)**
```bash
# Create Workbook in Portal (manual)
# - No code changes needed
# - Takes 15 minutes
# - Follow docs/WORKBOOK_GUIDE.md
```

**Phase 3: Grafana (Optional - Month 2+)**
```bash
# If you want Grafana later:
# - I'll add the Bicep module
# - Deploy separately
# - Import dashboards
```

---

## 🔧 FIXES I NEED TO MAKE

### 1. Update `modules/containerapps-env-vnet.bicep`

**Line ~230, add**:
```bicep
output containerAppResourceId string = containerApp.id
```

### 2. Update `modules/postgres-private.bicep`

**Line ~155, add**:
```bicep
output serverResourceId string = postgresqlServer.id
```

### 3. Update `main.bicep`

**After module #11, add**:
```bicep
// 12. Monitoring & Alerts
module monitoring 'modules/monitoring.bicep' = { ... }
```

**Add to outputs section**:
```bicep
// Monitoring
output criticalActionGroupId string = monitoring.outputs.criticalActionGroupId
output warningActionGroupId string = monitoring.outputs.warningActionGroupId
output monitoringAlertCount int = length(monitoring.outputs.monitoringResourceIds)
```

---

## ✅ FINAL RECOMMENDATION

### DO NOT DEPLOY YET

**Reason**: Missing integration code will cause deployment to succeed WITHOUT monitoring

**Next Steps**:
1. ✅ **I'll fix the 3 code issues above** (2 minutes)
2. ⚠️ **YOU update email addresses** in parameters
3. ✅ **Run deployment** - monitoring will be included
4. ✅ **Test alerts** by triggering conditions
5. ✅ **Create Workbook** in Week 1 (optional but recommended)
6. ⏭️ **Consider Grafana** in Month 2+ if needed

---

## 🤔 GRAFANA DASHBOARD QUESTION - DETAILED ANSWER

### "Is it ready out of the box?"

**SHORT ANSWER**: No, Grafana dashboards require manual import/creation AFTER deployment.

**LONG ANSWER**:

#### What IS Ready Out of the Box (After Grafana Deployment):
1. ✅ Grafana instance running
2. ✅ Authentication configured (Azure AD)
3. ✅ Data sources connected (Log Analytics)
4. ✅ Permissions set up
5. ❌ NO dashboards pre-configured

#### What You Need to Do (15-30 min):
1. Login to Grafana
2. Import community dashboards (3 clicks per dashboard)
3. OR create custom dashboards (more time)

#### Why Not Auto-Configure Dashboards?

**Technical Reason**: 
- Dashboard JSON needs specific resource IDs
- IDs only known AFTER deployment
- Would require post-deployment script

**Practical Reason**:
- Teams have different preferences
- Better to import what YOU need
- Community has 1000+ options

#### Comparison:

| Tool | Dashboard Auto-Config | Setup Effort |
|------|----------------------|--------------|
| **Grafana** | ❌ Manual import | 30 min |
| **Workbooks** | ❌ Manual create | 15 min |
| **Dashboards** | ❌ Manual pin tiles | 5 min |
| **Alerts** | ✅ Auto-configured | 0 min ✅ |

### Bottom Line:

**Alerts** = Fully automated, ready immediately
**Dashboards** = Manual setup required (any tool)

This is NORMAL and expected for any monitoring solution!

---

## ⏭️ NEXT: SHALL I FIX THE CODE?

Say "yes, fix the code" and I'll:
1. ✅ Add missing outputs to 2 modules
2. ✅ Integrate monitoring into main.bicep
3. ✅ Update outputs
4. ✅ Verify everything compiles

Then you just need to:
1. ⚠️ Update email addresses
2. ✅ Run deployment

**Ready to proceed?**
