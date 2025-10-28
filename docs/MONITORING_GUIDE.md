# Monitoring & Alerting Guide

## Overview

This guide explains the comprehensive monitoring setup for the Case Management System, based on **Azure Monitor Baseline Alerts (AMBA)** recommendations and implemented using industry best practices.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Monitoring Stack                         │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐        ┌──────────────┐                   │
│  │ Container App│───────▶│ Log Analytics│                   │
│  │   (Backend)  │        │   Workspace  │                   │
│  └──────────────┘        └──────┬───────┘                   │
│                                  │                            │
│  ┌──────────────┐                │                            │
│  │  PostgreSQL  │───────────────▶│                            │
│  │   (Database) │                │                            │
│  └──────────────┘                │                            │
│                                  │                            │
│  ┌──────────────┐                │                            │
│  │     APIM     │───────────────▶│                            │
│  │    (API GW)  │                │                            │
│  └──────────────┘                │                            │
│                                  │                            │
│                                  ▼                            │
│                         ┌────────────────┐                   │
│                         │ Alert Rules    │                   │
│                         │ - Metric Alerts│                   │
│                         │ - Log Alerts   │                   │
│                         │ - Activity Log │                   │
│                         └───────┬────────┘                   │
│                                 │                             │
│                                 ▼                             │
│                         ┌────────────────┐                   │
│                         │ Action Groups  │                   │
│                         │ - Critical     │                   │
│                         │ - Warning      │                   │
│                         └───────┬────────┘                   │
│                                 │                             │
│                    ┌────────────┼────────────┐               │
│                    ▼            ▼            ▼               │
│                ┌──────┐    ┌──────┐    ┌──────┐             │
│                │Email │    │ SMS  │    │Webhook│             │
│                └──────┘    └──────┘    └──────┘             │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## What is AMBA?

**Azure Monitor Baseline Alerts (AMBA)** is a Microsoft-provided framework that offers:

- ✅ **Expert-curated alert configurations** for Azure services
- ✅ **Recommended thresholds** based on real-world experience
- ✅ **Service-specific guidance** for 100+ Azure resources
- ✅ **Policy-based deployment** for consistency at scale
- ✅ **Free to implement** (only pay for Azure Monitor itself)

**Official Documentation**: https://azure.github.io/azure-monitor-baseline-alerts/

## Alerts Implemented

### 🔴 Critical Alerts (Immediate Action Required)

| Alert | Service | Threshold | Reasoning |
|-------|---------|-----------|-----------|
| **Container Restarts** | Container App | >3 in 15min | Indicates application crashes or OOM kills |
| **HTTP 5xx Errors** | Container App | >10 in 15min | Backend failures affecting users |
| **PostgreSQL Storage** | PostgreSQL | >85% | Prevent database from running out of space |
| **PostgreSQL Connection Failures** | PostgreSQL | >5 in 15min | Database connectivity issues |
| **APIM Request Failures** | APIM | >10 in 15min | API gateway not working |
| **Application Errors in Logs** | Logs | >5 errors in 15min | Application-level failures |
| **Resource Deletion** | Activity Log | Any deletion | Security & operational safety |
| **Security Policy Changes** | Activity Log | Any change | Security compliance |

### 🟡 Warning Alerts (Monitor & Plan)

| Alert | Service | Threshold | Reasoning |
|-------|---------|-----------|-----------|
| **Container CPU** | Container App | >90% | Prevent performance degradation |
| **Container Memory** | Container App | >90% | Avoid OOM kills |
| **PostgreSQL CPU** | PostgreSQL | >90% | Database performance issue |
| **PostgreSQL Memory** | PostgreSQL | >90% | May need to scale up |
| **APIM Latency** | APIM | >5 seconds | Slow API responses |

## Alert Severity Levels

- **Severity 0 (Critical)**: Service down, immediate action required
- **Severity 1 (High)**: Service degraded, action required soon
- **Severity 2 (Warning)**: Potential issue, plan action
- **Severity 3 (Informational)**: FYI, no action needed
- **Severity 4 (Verbose)**: Detailed information

## Action Groups

### Critical Action Group
- **Purpose**: Immediate notifications for production issues
- **Channels**: Email, SMS (optional), Webhooks
- **Response Time**: < 5 minutes
- **Use Cases**: Service outages, data loss risks, security events

### Warning Action Group
- **Purpose**: Proactive notifications for potential issues
- **Channels**: Email, Webhooks
- **Response Time**: < 30 minutes
- **Use Cases**: Resource exhaustion, performance degradation

## Integration with Azure Verified Modules (AVM)

The monitoring setup can optionally use these AVM modules for enhanced functionality:

```bicep
// Example: Using AVM for Action Groups
module actionGroup 'br/public:avm/res/insights/action-group:0.8.0' = {
  name: 'action-group-deployment'
  params: {
    name: 'ag-critical'
    emailReceivers: [
      {
        name: 'Admin'
        emailAddress: 'admin@example.com'
      }
    ]
  }
}
```

### Recommended AVM Modules

1. **`avm/res/insights/action-group`** - Enhanced action group management
2. **`avm/res/insights/metric-alert`** - Simplified metric alerts
3. **`avm/res/insights/scheduled-query-rule`** - Log-based alerts
4. **`avm/ptn/azd/monitoring`** - Complete monitoring pattern with Application Insights

## Deployment

### 1. Update Main Bicep File

Add the monitoring module to `main.bicep`:

```bicep
// After all resources are deployed
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring-deployment'
  params: {
    baseName: baseName
    environmentName: environmentName
    location: location
    logAnalyticsWorkspaceId: logs.outputs.logAnalyticsId
    containerAppId: containerAppsEnv.outputs.containerAppResourceId
    staticWebAppId: staticWebApp.outputs.staticWebAppId
    postgresqlServerId: postgresqlPrivate.outputs.serverResourceId
    apimId: apiManagement.outputs.apimResourceId
    alertEmails: [
      'your-email@example.com'
      'team-email@example.com'
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

### 2. Deploy

```powershell
# Deploy with monitoring
az deployment group create `
  --resource-group rg-casemanagement-dev `
  --template-file infra/bicep/main.bicep `
  --parameters infra/bicep/main.parameters.dev-optimized.json
```

## Cost Considerations

### Azure Monitor Pricing (Pay-as-you-go)

| Component | Cost | Notes |
|-----------|------|-------|
| **Log Analytics Ingestion** | ~$2.76/GB | First 5GB/month free |
| **Log Analytics Retention** | ~$0.12/GB/month | After 30 days |
| **Metric Alerts** | $0.10/alert/month | First 10 free |
| **Log Alerts** | $1.50/alert/month | First 5 free |
| **Action Groups** | Free | Unlimited |

### Estimated Monthly Cost (Dev Environment)

- Log ingestion: ~1GB/day = ~$82/month (after free tier)
- 15 metric alerts = $0.50/month (after free tier)
- 2 log alerts = Free (under 5)
- **Total**: ~$83/month

### Cost Optimization Tips

1. **Use sampling** for high-volume logs
2. **Set retention** to 30 days for dev/test
3. **Disable verbose logging** in production
4. **Use log-based metrics** instead of custom metrics where possible

## Viewing Alerts

### Azure Portal

1. Navigate to **Monitor** → **Alerts**
2. Filter by:
   - Resource Group: `rg-casemanagement-dev`
   - Severity: Critical, High
   - Time range: Last 24 hours

### Azure CLI

```powershell
# List fired alerts
az monitor metrics alert list `
  --resource-group rg-casemanagement-dev

# Get alert details
az monitor metrics alert show `
  --resource-group rg-casemanagement-dev `
  --name alert-casemanagement-containerapp-cpu-dev
```

## Log Queries (KQL)

### Common Queries

#### 1. Application Errors
```kql
ContainerAppConsoleLogs_CL
| where Log_s contains "ERROR" or Log_s contains "Exception"
| where TimeGenerated > ago(1h)
| summarize Count = count() by bin(TimeGenerated, 5m), ContainerAppName_s
| render timechart
```

#### 2. API Response Times
```kql
ApiManagementGatewayLogs
| where TimeGenerated > ago(1h)
| summarize avg(DurationMs), max(DurationMs), min(DurationMs) 
  by bin(TimeGenerated, 5m)
| render timechart
```

#### 3. Database Connections
```kql
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.DBFORPOSTGRESQL"
| where Category == "PostgreSQLLogs"
| where Message contains "connection"
| summarize Count = count() by bin(TimeGenerated, 5m)
| render timechart
```

#### 4. Failed Requests by Status Code
```kql
ContainerAppSystemLogs_CL
| where StatusCode_d >= 400
| summarize Count = count() by StatusCode_d, bin(TimeGenerated, 5m)
| render columnchart
```

## Dashboards

### Creating Custom Dashboard

1. Go to **Azure Portal** → **Dashboard**
2. Click **+ New dashboard**
3. Add tiles:
   - **Metric Chart**: Container App CPU/Memory
   - **Metric Chart**: PostgreSQL Storage
   - **Logs**: Recent Errors (KQL query)
   - **Alerts**: Active Alerts list

### Recommended Tiles

- 📊 Container App CPU & Memory over time
- 📊 PostgreSQL Connections over time
- 📊 API Request count and latency
- 📋 Top 10 errors from logs
- 🚨 Critical alerts in last 24 hours

## Integration with Teams/Slack

### Microsoft Teams

```bicep
resource teamActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  properties: {
    webhookReceivers: [
      {
        name: 'Teams'
        serviceUri: 'https://outlook.office.com/webhook/xxx' // Teams webhook URL
        useCommonAlertSchema: true
      }
    ]
  }
}
```

### Slack

```bicep
resource slackActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  properties: {
    webhookReceivers: [
      {
        name: 'Slack'
        serviceUri: 'https://hooks.slack.com/services/xxx' // Slack webhook URL
        useCommonAlertSchema: false
      }
    ]
  }
}
```

## Best Practices

### 1. Alert Tuning
- ✅ Start with AMBA recommendations
- ✅ Adjust thresholds based on your workload
- ✅ Review alert history monthly
- ✅ Reduce false positives

### 2. Alert Fatigue Prevention
- ✅ Use appropriate severity levels
- ✅ Group related alerts
- ✅ Implement auto-resolution
- ✅ Set proper evaluation windows

### 3. Response Procedures
- ✅ Document response playbooks
- ✅ Define escalation paths
- ✅ Set up on-call rotations
- ✅ Review incidents post-mortem

### 4. Continuous Improvement
- ✅ Track alert effectiveness
- ✅ Measure MTTD (Mean Time To Detect)
- ✅ Measure MTTR (Mean Time To Resolve)
- ✅ Iterate on thresholds

## Advanced: Application Insights

For deeper application monitoring, consider adding Application Insights:

```bicep
module appInsights 'br/public:avm/res/insights/component:0.6.1' = {
  name: 'app-insights'
  params: {
    name: 'appi-${baseName}-${environmentName}'
    workspaceResourceId: logAnalyticsWorkspaceId
    applicationType: 'web'
  }
}
```

### Benefits
- 📈 Application performance monitoring (APM)
- 🔍 Distributed tracing
- 📊 User analytics
- 🐛 Exception tracking
- 💡 Smart detection (AI-powered anomaly detection)

## Troubleshooting

### Alert Not Firing

1. **Check if metrics are being collected**
   ```powershell
   az monitor metrics list `
     --resource <resource-id> `
     --metric-names cpu_percent
   ```

2. **Verify alert is enabled**
   ```powershell
   az monitor metrics alert show `
     --resource-group rg-casemanagement-dev `
     --name alert-name
   ```

3. **Check evaluation frequency and window size** - Ensure data points exist for the window

### Alert Firing Too Often

1. **Adjust threshold** - Increase threshold or extend window
2. **Check for anomalies** - Investigate if there's a real issue
3. **Review aggregation type** - Use appropriate aggregation (avg vs max)

## Resources

- 📚 [AMBA Official Documentation](https://azure.github.io/azure-monitor-baseline-alerts/)
- 📚 [Azure Monitor Best Practices](https://learn.microsoft.com/azure/azure-monitor/best-practices)
- 📚 [Azure Verified Modules](https://aka.ms/AVM)
- 📚 [KQL Reference](https://learn.microsoft.com/azure/data-explorer/kusto/query/)
- 📚 [Alert Processing Rules](https://learn.microsoft.com/azure/azure-monitor/alerts/alerts-processing-rules)

## Next Steps

1. ✅ Deploy monitoring module
2. ⬜ Set up email notifications
3. ⬜ Create custom dashboard
4. ⬜ Document incident response procedures
5. ⬜ Configure Teams/Slack integration
6. ⬜ Enable Application Insights (optional)
7. ⬜ Set up automated reports
8. ⬜ Implement chaos engineering tests
