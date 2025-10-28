# 📊 Azure Workbook Setup Guide (FREE)

**Cost**: $0/month (completely free!)  
**Setup Time**: 15 minutes  
**Skill Level**: Beginner-friendly

---

## 🎯 What You'll Get

A comprehensive monitoring dashboard with:
- 📈 Container App metrics (CPU, memory, requests, errors)
- 🗄️ PostgreSQL metrics (CPU, memory, storage, connections)
- 🌐 API Management metrics (latency, failures, throughput)
- 📝 Recent error logs from all services
- 🔔 Active alerts status

**Screenshot Preview**:
```
┌─────────────────────────────────────────────────────────┐
│  Case Management System - Monitoring Dashboard          │
├─────────────────────────────────────────────────────────┤
│  [Last 1 Hour ▼]  [Auto-refresh: 5 min ▼]  [Refresh]   │
├─────────────────────────────────────────────────────────┤
│  Container App Health                                    │
│  ┌───────────┬───────────┬───────────┬───────────┐      │
│  │ CPU: 45%  │ Mem: 62%  │ Req: 1.2K │ Err: 3    │      │
│  └───────────┴───────────┴───────────┴───────────┘      │
│  [CPU % over time - line chart]                         │
│                                                          │
│  PostgreSQL Health                                       │
│  ┌───────────┬───────────┬───────────┬───────────┐      │
│  │ CPU: 32%  │ Mem: 55%  │ Stor: 48% │ Conn: 12  │      │
│  └───────────┴───────────┴───────────┴───────────┘      │
│  [Storage % over time - line chart]                     │
│                                                          │
│  Recent Errors (Last Hour)                               │
│  ┌─────────────────────────────────────────────────┐    │
│  │ 15:23 | ERROR | Backend | Connection timeout    │    │
│  │ 15:18 | ERROR | Backend | 500 Internal Error    │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

---

## 📋 Prerequisites

Before starting, ensure you have:
- ✅ Deployed infrastructure with monitoring alerts
- ✅ Log Analytics workspace created
- ✅ Container Apps, PostgreSQL, APIM running
- ✅ Azure Portal access with Contributor/Reader role

---

## 🚀 Quick Start (3 Steps)

### Step 1: Open Azure Monitor Workbooks

1. Go to [Azure Portal](https://portal.azure.com)
2. Search for "Monitor" in the top search bar
3. Click **Monitor** from results
4. In left menu, click **Workbooks**
5. Click **+ New**

### Step 2: Import Template

Two options:

#### Option A: Use Gallery Template (Easiest - 5 minutes)

1. Click **Gallery** button
2. Search for "Azure Monitor"
3. Select **"Azure Monitor - Overview"**
4. Click **Open**
5. Customize resources:
   - Click "Edit" (top toolbar)
   - Update resource dropdowns to your resources
   - Click "Done Editing"
6. Click **Save** (floppy disk icon)
7. Name: "Case Management Monitoring"
8. Save to your resource group

#### Option B: Import Custom Template (Recommended - 15 minutes)

1. Click **Advanced Editor** button (</> icon, top toolbar)
2. Copy the JSON template from `WORKBOOK_TEMPLATE.json` (see below)
3. Paste into editor
4. Click **Apply**
5. Update the resource IDs in the queries:
   - Find `{CONTAINER_APP_ID}` → Replace with your Container App resource ID
   - Find `{POSTGRES_ID}` → Replace with your PostgreSQL resource ID
   - Find `{APIM_ID}` → Replace with your APIM resource ID
6. Click **Done Editing**
7. Click **Save**

### Step 3: Pin to Dashboard (Optional)

1. Click **Pin** icon (📌) on any chart
2. Create new dashboard OR add to existing
3. Share dashboard with team

---

## 📦 Workbook Template (JSON)

Save this as `WORKBOOK_TEMPLATE.json` and import via Advanced Editor:

```json
{
  "version": "Notebook/1.0",
  "items": [
    {
      "type": 1,
      "content": {
        "json": "## 🎯 Case Management System - Monitoring Dashboard\n\n**Last Updated**: {TimeRange:label}\n\nThis dashboard provides real-time monitoring of your FastAPI backend, PostgreSQL database, and API Management gateway."
      },
      "name": "header-text"
    },
    {
      "type": 9,
      "content": {
        "version": "KqlParameterItem/1.0",
        "parameters": [
          {
            "id": "time-range-picker",
            "version": "KqlParameterItem/1.0",
            "name": "TimeRange",
            "type": 4,
            "isRequired": true,
            "value": {
              "durationMs": 3600000
            },
            "typeSettings": {
              "selectableValues": [
                {
                  "durationMs": 300000,
                  "createdTime": "2023-01-01T00:00:00.000Z",
                  "isInitialTime": false,
                  "grain": 1,
                  "useDashboardTimeRange": false
                },
                {
                  "durationMs": 900000,
                  "createdTime": "2023-01-01T00:00:00.000Z",
                  "isInitialTime": false,
                  "grain": 1,
                  "useDashboardTimeRange": false
                },
                {
                  "durationMs": 3600000,
                  "createdTime": "2023-01-01T00:00:00.000Z",
                  "isInitialTime": false,
                  "grain": 1,
                  "useDashboardTimeRange": false
                },
                {
                  "durationMs": 14400000,
                  "createdTime": "2023-01-01T00:00:00.000Z",
                  "isInitialTime": false,
                  "grain": 1,
                  "useDashboardTimeRange": false
                },
                {
                  "durationMs": 86400000,
                  "createdTime": "2023-01-01T00:00:00.000Z",
                  "isInitialTime": false,
                  "grain": 1,
                  "useDashboardTimeRange": false
                },
                {
                  "durationMs": 604800000,
                  "createdTime": "2023-01-01T00:00:00.000Z",
                  "isInitialTime": false,
                  "grain": 1,
                  "useDashboardTimeRange": false
                }
              ]
            },
            "timeContextFromParameter": "TimeRange",
            "label": "Time Range"
          }
        ],
        "style": "pills",
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces"
      },
      "name": "parameters-time-range"
    },
    {
      "type": 1,
      "content": {
        "json": "---\n### 🐳 Container App (FastAPI Backend)"
      },
      "name": "container-app-header"
    },
    {
      "type": 10,
      "content": {
        "chartId": "container-app-metrics",
        "version": "MetricsItem/2.0",
        "size": 0,
        "chartType": 2,
        "resourceIds": [
          "/subscriptions/{SUBSCRIPTION_ID}/resourceGroups/{RESOURCE_GROUP}/providers/Microsoft.App/containerApps/{CONTAINER_APP_NAME}"
        ],
        "timeContext": {
          "durationMs": 0
        },
        "timeContextFromParameter": "TimeRange",
        "metrics": [
          {
            "namespace": "microsoft.app/containerapps",
            "metric": "microsoft.app/containerapps--UsageNanoCores",
            "aggregation": 4,
            "splitBy": null
          },
          {
            "namespace": "microsoft.app/containerapps",
            "metric": "microsoft.app/containerapps--WorkingSetBytes",
            "aggregation": 4
          },
          {
            "namespace": "microsoft.app/containerapps",
            "metric": "microsoft.app/containerapps--Requests",
            "aggregation": 7
          }
        ],
        "title": "Container App Health (CPU, Memory, Requests)",
        "gridSettings": {
          "rowLimit": 10000
        }
      },
      "name": "container-app-chart"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "ContainerAppConsoleLogs_CL\n| where TimeGenerated {TimeRange}\n| where Log_s contains \"ERROR\" or Log_s contains \"Exception\" or Log_s contains \"Failed\"\n| project TimeGenerated, ContainerAppName_s, Log_s\n| order by TimeGenerated desc\n| take 20",
        "size": 0,
        "title": "Recent Backend Errors",
        "timeContext": {
          "durationMs": 0
        },
        "timeContextFromParameter": "TimeRange",
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces",
        "gridSettings": {
          "formatters": [
            {
              "columnMatch": "TimeGenerated",
              "formatter": 6,
              "dateFormat": {
                "showUtcTime": null,
                "formatName": "shortDateTimePattern"
              }
            },
            {
              "columnMatch": "Log_s",
              "formatter": 1,
              "formatOptions": {
                "customColumnWidthSetting": "60%"
              }
            }
          ],
          "rowLimit": 20,
          "filter": true
        }
      },
      "customWidth": "50",
      "name": "backend-errors-grid"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "ContainerAppConsoleLogs_CL\n| where TimeGenerated {TimeRange}\n| where Log_s contains \"ERROR\"\n| summarize ErrorCount = count() by bin(TimeGenerated, 5m)\n| render timechart",
        "size": 0,
        "title": "Error Rate Over Time",
        "timeContext": {
          "durationMs": 0
        },
        "timeContextFromParameter": "TimeRange",
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces"
      },
      "customWidth": "50",
      "name": "error-rate-chart"
    },
    {
      "type": 1,
      "content": {
        "json": "---\n### 🗄️ PostgreSQL Database"
      },
      "name": "postgres-header"
    },
    {
      "type": 10,
      "content": {
        "chartId": "postgres-metrics",
        "version": "MetricsItem/2.0",
        "size": 0,
        "chartType": 2,
        "resourceIds": [
          "/subscriptions/{SUBSCRIPTION_ID}/resourceGroups/{RESOURCE_GROUP}/providers/Microsoft.DBforPostgreSQL/flexibleServers/{POSTGRES_NAME}"
        ],
        "timeContext": {
          "durationMs": 0
        },
        "timeContextFromParameter": "TimeRange",
        "metrics": [
          {
            "namespace": "microsoft.dbforpostgresql/flexibleservers",
            "metric": "microsoft.dbforpostgresql/flexibleservers--cpu_percent",
            "aggregation": 4
          },
          {
            "namespace": "microsoft.dbforpostgresql/flexibleservers",
            "metric": "microsoft.dbforpostgresql/flexibleservers--memory_percent",
            "aggregation": 4
          },
          {
            "namespace": "microsoft.dbforpostgresql/flexibleservers",
            "metric": "microsoft.dbforpostgresql/flexibleservers--storage_percent",
            "aggregation": 4
          },
          {
            "namespace": "microsoft.dbforpostgresql/flexibleservers",
            "metric": "microsoft.dbforpostgresql/flexibleservers--active_connections",
            "aggregation": 4
          }
        ],
        "title": "Database Health (CPU, Memory, Storage, Connections)",
        "gridSettings": {
          "rowLimit": 10000
        }
      },
      "name": "postgres-chart"
    },
    {
      "type": 1,
      "content": {
        "json": "---\n### 🌐 API Management"
      },
      "name": "apim-header"
    },
    {
      "type": 10,
      "content": {
        "chartId": "apim-metrics",
        "version": "MetricsItem/2.0",
        "size": 0,
        "chartType": 2,
        "resourceIds": [
          "/subscriptions/{SUBSCRIPTION_ID}/resourceGroups/{RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/{APIM_NAME}"
        ],
        "timeContext": {
          "durationMs": 0
        },
        "timeContextFromParameter": "TimeRange",
        "metrics": [
          {
            "namespace": "microsoft.apimanagement/service",
            "metric": "microsoft.apimanagement/service--TotalRequests",
            "aggregation": 7
          },
          {
            "namespace": "microsoft.apimanagement/service",
            "metric": "microsoft.apimanagement/service--FailedRequests",
            "aggregation": 7
          },
          {
            "namespace": "microsoft.apimanagement/service",
            "metric": "microsoft.apimanagement/service--Duration",
            "aggregation": 4
          }
        ],
        "title": "API Gateway Health (Requests, Failures, Latency)",
        "gridSettings": {
          "rowLimit": 10000
        }
      },
      "name": "apim-chart"
    },
    {
      "type": 1,
      "content": {
        "json": "---\n### 🔔 Active Alerts"
      },
      "name": "alerts-header"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "AlertsManagementResources\n| where type == \"microsoft.alertsmanagement/alerts\"\n| where properties.essentials.monitorCondition == \"Fired\"\n| where properties.essentials.startDateTime >= ago(24h)\n| project \n    AlertName = properties.essentials.alertRule,\n    Severity = properties.essentials.severity,\n    FiredTime = properties.essentials.startDateTime,\n    Resource = split(properties.essentials.targetResourceName, '/')[(-1)],\n    Status = properties.essentials.alertState\n| order by FiredTime desc",
        "size": 0,
        "title": "Active Alerts (Last 24 Hours)",
        "queryType": 1,
        "resourceType": "microsoft.resourcegraph/resources",
        "crossComponentResources": [
          "value::all"
        ],
        "gridSettings": {
          "formatters": [
            {
              "columnMatch": "Severity",
              "formatter": 18,
              "formatOptions": {
                "thresholdsOptions": "icons",
                "thresholdsGrid": [
                  {
                    "operator": "==",
                    "thresholdValue": "Sev0",
                    "representation": "4",
                    "text": "Critical"
                  },
                  {
                    "operator": "==",
                    "thresholdValue": "Sev1",
                    "representation": "critical",
                    "text": "Error"
                  },
                  {
                    "operator": "==",
                    "thresholdValue": "Sev2",
                    "representation": "2",
                    "text": "Warning"
                  },
                  {
                    "operator": "Default",
                    "thresholdValue": null,
                    "representation": "success",
                    "text": "Info"
                  }
                ]
              }
            },
            {
              "columnMatch": "FiredTime",
              "formatter": 6
            }
          ],
          "rowLimit": 50
        }
      },
      "name": "active-alerts-grid"
    }
  ],
  "fallbackResourceIds": [
    "/subscriptions/{SUBSCRIPTION_ID}/resourceGroups/{RESOURCE_GROUP}/providers/Microsoft.OperationalInsights/workspaces/{LOG_ANALYTICS_WORKSPACE}"
  ],
  "fromTemplateId": "sentinel-UserWorkbook",
  "$schema": "https://github.com/Microsoft/Application-Insights-Workbooks/blob/master/schema/workbook.json"
}
```

**⚠️ IMPORTANT**: Replace these placeholders before importing:
- `{SUBSCRIPTION_ID}` - Your Azure subscription ID
- `{RESOURCE_GROUP}` - Your resource group name
- `{CONTAINER_APP_NAME}` - Your Container App name
- `{POSTGRES_NAME}` - Your PostgreSQL server name
- `{APIM_NAME}` - Your APIM instance name
- `{LOG_ANALYTICS_WORKSPACE}` - Your Log Analytics workspace name

---

## 🔍 How to Find Resource IDs

### Method 1: Azure Portal (Easy)

1. Go to your resource (Container App, PostgreSQL, etc.)
2. Click **JSON View** (top right)
3. Copy **Resource ID** from the popup
4. Paste into template

### Method 2: Azure CLI (Fast)

```powershell
# Get Container App ID
az containerapp show --name <app-name> --resource-group <rg-name> --query id -o tsv

# Get PostgreSQL ID
az postgres flexible-server show --name <db-name> --resource-group <rg-name> --query id -o tsv

# Get APIM ID
az apim show --name <apim-name> --resource-group <rg-name> --query id -o tsv
```

### Method 3: From Deployment Outputs

After running your Bicep deployment, check outputs:
```powershell
az deployment group show --name <deployment-name> --resource-group <rg-name> --query properties.outputs
```

---

## 🎨 Customization Options

### Add More Charts

1. Click **Edit** (top toolbar)
2. Click **+ Add** → **Add metric**
3. Select resource and metric
4. Configure chart type
5. Click **Done Editing**

### Change Time Ranges

- Default: Last 1 hour
- Options: 5min, 15min, 1hr, 4hr, 24hr, 7 days
- Auto-refresh: 5 minutes (configurable)

### Add Filters

1. Edit any grid/chart
2. Click **Add parameter**
3. Create dropdown for filtering (e.g., by severity, resource)
4. Apply filter to queries

### Share with Team

1. Click **Share** (top toolbar)
2. Options:
   - **Link**: Copy shareable URL
   - **Pin to Dashboard**: Add to shared dashboard
   - **Export**: Download JSON
   - **Permissions**: Manage access

---

## 📊 Alternative: Quick Dashboard (5 Minutes)

If you want something SUPER simple:

### Option 1: Azure Portal Dashboard

1. Go to Azure Portal → **Dashboard**
2. Click **+ New dashboard**
3. Name: "Case Management Monitoring"
4. Drag **Metrics chart** tile onto dashboard
5. Configure each tile:
   - Select resource (Container App, PostgreSQL, APIM)
   - Select metric (CPU, Memory, etc.)
   - Set time range
6. Click **Done customizing**
7. **Share** with team

**Pros**:
- ✅ 5 minute setup
- ✅ No JSON editing
- ✅ Point-and-click

**Cons**:
- ❌ Less flexible than Workbooks
- ❌ Basic charts only
- ❌ No log queries

### Option 2: Pin Metrics from Resource Pages

1. Go to any resource (Container App, PostgreSQL)
2. Click **Metrics** in left menu
3. Add metric (CPU, Memory, etc.)
4. Click **Pin to dashboard** (📌 icon)
5. Select existing dashboard or create new
6. Repeat for all resources

**Fastest** but least powerful option.

---

## 🚨 Troubleshooting

### "No data available"

**Cause**: Resource hasn't generated metrics yet OR wrong resource ID

**Fix**:
1. Verify resource is running
2. Check resource ID is correct (copy from portal)
3. Wait 5-10 minutes for metrics to populate
4. Try expanding time range to "Last 24 hours"

### "Query failed" for Container App logs

**Cause**: `ContainerAppConsoleLogs_CL` table doesn't exist yet

**Fix**:
1. Container Apps take ~15 minutes to start sending logs
2. Check Log Analytics workspace has data:
   ```kql
   search "*"
   | where TimeGenerated > ago(1h)
   | summarize count() by $table
   ```
3. If no `ContainerAppConsoleLogs_CL`, wait or check diagnostic settings

### "Access denied"

**Cause**: Insufficient permissions on resources

**Fix**:
1. Ensure you have **Reader** role on resources
2. OR **Monitoring Reader** role on subscription
3. Ask admin to grant access

### Charts look weird

**Cause**: Metrics aggregation mismatch

**Fix**:
1. Edit chart
2. Try different aggregations:
   - CPU/Memory: Average
   - Requests: Sum or Count
   - Errors: Count
3. Adjust time granularity (1min, 5min, 1hr)

---

## 📚 Next Steps

After setting up your workbook:

### Week 1
- ✅ Use workbook daily
- ✅ Tune alert thresholds based on actual usage
- ✅ Add custom queries for specific issues

### Week 2-4
- ✅ Create additional workbooks for specific scenarios:
  - Security monitoring
  - Cost analysis
  - User activity
- ✅ Share workbooks with team
- ✅ Set up scheduled email snapshots

### Month 2+
- ⏭️ Evaluate if Azure Managed Grafana is needed ($240/month)
- ⏭️ Advantages: Better for multi-cloud, more community dashboards
- ⏭️ Stick with Workbooks if current solution meets needs (FREE!)

---

## 💡 Pro Tips

1. **Save Multiple Versions**: Create workbooks for different audiences:
   - `Monitoring - Developer` (detailed logs, errors)
   - `Monitoring - Management` (high-level KPIs)
   - `Monitoring - Ops` (infrastructure health)

2. **Use Parameters**: Add dropdowns to filter by:
   - Environment (dev, staging, prod)
   - Time range
   - Resource group
   - Severity

3. **Scheduled Exports**: Set up Logic Apps to email workbook snapshots daily

4. **Mobile Access**: Workbooks work on mobile browsers (Azure Mobile App)

5. **Version Control**: Export workbook JSON and commit to Git

---

## ✅ Checklist

Before you finish:

- [ ] Created workbook in Azure Portal
- [ ] Updated resource IDs in queries
- [ ] Verified all charts show data
- [ ] Saved workbook to resource group
- [ ] Pinned key charts to dashboard
- [ ] Shared with team members
- [ ] Tested on mobile device
- [ ] Exported JSON backup to Git

---

## 🆘 Need Help?

**Documentation**:
- [Azure Workbooks Docs](https://learn.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-overview)
- [KQL Query Language](https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/)
- [Container App Metrics](https://learn.microsoft.com/en-us/azure/container-apps/observability)

**Sample Queries**:
See `MONITORING_GUIDE.md` for more KQL examples

**Support**:
If charts aren't working, share:
1. Screenshot of error
2. Resource ID you're using
3. Your Azure role/permissions

I can help debug!
