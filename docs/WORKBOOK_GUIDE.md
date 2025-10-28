# Azure Workbook Template - Case Management System Monitoring

This workbook provides a comprehensive view of your Case Management System's health and performance.

## Deploy This Workbook

### Option 1: Azure Portal (Manual)

1. Go to **Azure Portal** → **Monitor** → **Workbooks**
2. Click **+ New**
3. Click **Advanced Editor** (</> icon)
4. Paste the JSON from `workbook-template.json` (see below)
5. Click **Apply**
6. Click **Done Editing**
7. Click **Save** → Name it "Case Management System Health"

### Option 2: ARM Template (Automated)

Deploy using Azure CLI:

```powershell
az deployment group create `
  --resource-group rg-casemanagement-dev `
  --template-file infra/bicep/modules/workbook.bicep `
  --parameters workbookName="Case Management System Health"
```

## Workbook Content

The workbook includes these sections:

### 📊 Overview Dashboard
- System health status
- Active critical alerts
- Key metrics summary
- Recent errors

### 🖥️ Backend (Container App)
- CPU and Memory usage over time
- Request rate and latency
- HTTP status code distribution
- Restart count
- Top errors from logs

### 💾 Database (PostgreSQL)
- Connection count
- CPU and Memory usage
- Storage usage trend
- Query performance
- Failed connections
- Active/idle connections ratio

### 🌐 API Gateway (APIM)
- Request throughput
- Response time percentiles (50th, 95th, 99th)
- Success vs failure rate
- Top APIs by request count
- Error breakdown by API

### 📧 Email Service (ACS)
- Emails sent today
- Email delivery rate
- Failed emails
- Email queue length

### 🚨 Alerts & Incidents
- Active alerts by severity
- Alert history (last 24h)
- Most frequent alerts
- MTTR (Mean Time To Resolve)

### 📝 Logs Analysis
- Error rate over time
- Top error messages
- Errors by component
- Recent exceptions with stack traces

## Sharing Workbooks

### With Your Team

1. Open the workbook
2. Click **Share**
3. Options:
   - **Share link** - Anyone with link can view
   - **Assign permissions** - Specific users/groups
   - **Pin to dashboard** - Add to Azure Dashboard

### Export as PDF

1. Open workbook
2. Click the **...** menu
3. Select **Print** or **Export to PDF**

## Customization

### Add Custom Metrics

Edit the workbook and add a new query:

```kql
// Example: Custom business metric
AppTraces
| where TimeGenerated > ago(24h)
| where Properties contains "TicketCreated"
| summarize TicketCount = count() by bin(TimeGenerated, 1h)
| render timechart
```

### Add Custom Visualizations

The workbook supports:
- 📈 Line charts (time series)
- 📊 Bar charts
- 🥧 Pie charts
- 🗺️ Heat maps
- 🔢 Metrics tiles
- 📋 Grid (tables)

### Parameters

Add interactive filters:

```json
{
  "name": "TimeRange",
  "type": "TimeRangePicker",
  "description": "Select time range for all queries",
  "value": {
    "durationMs": 86400000
  }
}
```

## Workbook Template (JSON)

Save this as `workbook-template.json`:

```json
{
  "version": "Notebook/1.0",
  "items": [
    {
      "type": 1,
      "content": {
        "json": "## Case Management System - Health Dashboard\n\nReal-time monitoring based on Azure Monitor Baseline Alerts (AMBA) best practices."
      },
      "name": "Header"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "InsightsMetrics\n| where TimeGenerated > ago(1h)\n| where Namespace == \"container.azm.ms/containers\"\n| where Name == \"cpuUsageNanoCores\"\n| summarize CPU_Avg = avg(Val) by bin(TimeGenerated, 5m)\n| extend CPU_Percent = CPU_Avg / 10000000\n| render timechart",
        "size": 0,
        "title": "Container App - CPU Usage (%)",
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces"
      },
      "name": "ContainerCPU"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "InsightsMetrics\n| where TimeGenerated > ago(1h)\n| where Namespace == \"container.azm.ms/containers\"\n| where Name == \"memoryWorkingSetBytes\"\n| summarize Memory_Avg = avg(Val) by bin(TimeGenerated, 5m)\n| extend Memory_MB = Memory_Avg / 1048576\n| render timechart",
        "size": 0,
        "title": "Container App - Memory Usage (MB)",
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces"
      },
      "name": "ContainerMemory"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "AzureDiagnostics\n| where ResourceProvider == \"MICROSOFT.DBFORPOSTGRESQL\"\n| where Category == \"PostgreSQLLogs\"\n| where TimeGenerated > ago(1h)\n| summarize ConnectionCount = count() by bin(TimeGenerated, 5m)\n| render timechart",
        "size": 0,
        "title": "PostgreSQL - Connection Count",
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces"
      },
      "name": "PostgreSQLConnections"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "ContainerAppConsoleLogs_CL\n| where Log_s contains \"ERROR\" or Log_s contains \"Exception\"\n| where TimeGenerated > ago(24h)\n| summarize ErrorCount = count() by bin(TimeGenerated, 1h)\n| render columnchart",
        "size": 0,
        "title": "Application Errors (Last 24h)",
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces"
      },
      "name": "ApplicationErrors"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "AzureActivity\n| where TimeGenerated > ago(24h)\n| where CategoryValue == \"Administrative\"\n| summarize count() by OperationNameValue, Caller\n| order by count_ desc\n| take 10",
        "size": 0,
        "title": "Recent Administrative Operations",
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces"
      },
      "name": "AdminOperations"
    }
  ],
  "styleSettings": {},
  "$schema": "https://github.com/Microsoft/Application-Insights-Workbooks/blob/master/schema/workbook.json"
}
```

## Best Practices

### 1. Regular Reviews
- Review workbook **daily** for dev/test
- Review workbook **hourly** for production
- Share with team in daily standup

### 2. Customize for Your Needs
- Add business metrics (tickets created, resolved)
- Add SLA tracking
- Add cost analysis charts

### 3. Set Refresh Intervals
- Critical dashboards: 1-5 minutes
- Operational dashboards: 15 minutes
- Analytical dashboards: 1 hour

### 4. Mobile Access
- Workbooks work on mobile browsers
- Pin key charts to Azure mobile app
- Set up mobile-friendly alerts

## Advanced Features

### Time Range Selection

Add a time range parameter to make all charts interactive:

```json
{
  "type": 9,
  "content": {
    "version": "ParametersItem/1.0",
    "parameters": [
      {
        "name": "TimeRange",
        "type": 4,
        "value": {
          "durationMs": 3600000
        }
      }
    ]
  }
}
```

### Drill-Down

Enable clicking on chart elements to filter other charts:

```json
{
  "exportParameters": true,
  "exportParameterName": "SelectedResource"
}
```

### Conditional Formatting

Highlight problems with colors:

```json
{
  "thresholds": [
    {
      "value": 90,
      "operator": ">",
      "color": "red"
    },
    {
      "value": 75,
      "operator": ">",
      "color": "orange"
    }
  ]
}
```

## Integration with Grafana

If your team prefers Grafana:

1. Enable **Azure Managed Grafana**
2. Connect to Log Analytics workspace
3. Import dashboard from `grafana-dashboard.json`
4. Share with team

Benefits:
- Multi-cloud support
- Rich plugin ecosystem
- More visualization options
- Better for DevOps teams

## Resources

- 📚 [Azure Workbooks Documentation](https://learn.microsoft.com/azure/azure-monitor/visualize/workbooks-overview)
- 📚 [KQL Quick Reference](https://learn.microsoft.com/azure/data-explorer/kql-quick-reference)
- 📚 [Azure Managed Grafana](https://learn.microsoft.com/azure/managed-grafana/)
- 💡 [Community Workbook Gallery](https://github.com/microsoft/Application-Insights-Workbooks)

---

**Ready to visualize?** Deploy the workbook and start monitoring! 📊
