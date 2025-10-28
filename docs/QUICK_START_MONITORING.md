# Quick Start: Monitoring Setup

This guide will help you add comprehensive monitoring to your Case Management System in **5 minutes**.

## Prerequisites

- Existing deployment of the case management system
- Azure CLI installed
- Owner or Contributor access to the resource group

## Step 1: Update main.bicep

Add this module declaration at the end of your `infra/bicep/main.bicep` file (before the outputs section):

```bicep
// 12. Monitoring & Alerts (Based on AMBA recommendations)
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring-deployment'
  params: {
    baseName: baseName
    environmentName: environmentName
    location: location
    logAnalyticsWorkspaceId: logs.outputs.logAnalyticsId
    containerAppId: containerAppsEnv.outputs.apiResourceId
    postgresqlServerId: postgresqlPrivate.outputs.serverResourceId
    apimId: apiManagement.outputs.apiResourceId
    alertEmails: [
      'your-email@example.com'  // Replace with your email
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

## Step 2: Update Outputs

Update the `containerAppsEnv` module output to include the resource ID. In `infra/bicep/modules/containerapps-env-vnet.bicep`, add:

```bicep
// Add this output
output apiResourceId string = containerApp.id
```

Update `postgresqlPrivate` module to export resource ID. In `infra/bicep/modules/postgres-private.bicep`, add:

```bicep
// Add this output
output serverResourceId string = postgresServer.id
```

Update `apiManagement` module to export resource ID. In `infra/bicep/modules/apim.bicep`, add:

```bicep
// Add this output
output apiResourceId string = apim.id
```

## Step 3: Deploy

```powershell
# Deploy the monitoring setup
az deployment group create `
  --resource-group rg-casemanagement-dev `
  --template-file infra/bicep/main.bicep `
  --parameters infra/bicep/main.parameters.dev-optimized.json
```

## Step 4: Verify

```powershell
# Check that alerts are created
az monitor metrics alert list `
  --resource-group rg-casemanagement-dev `
  --query "[].{Name:name, Enabled:enabled, Severity:severity}" `
  --output table
```

Expected output:
```
Name                                                    Enabled    Severity
------------------------------------------------------  ---------  ----------
alert-casemanagement-containerapp-cpu-dev               True       2
alert-casemanagement-containerapp-memory-dev            True       2
alert-casemanagement-containerapp-restarts-dev          True       1
alert-casemanagement-containerapp-http5xx-dev           True       1
alert-casemanagement-postgresql-cpu-dev                 True       2
alert-casemanagement-postgresql-memory-dev              True       2
alert-casemanagement-postgresql-storage-dev             True       1
alert-casemanagement-postgresql-connections-dev         True       1
alert-casemanagement-apim-latency-dev                   True       2
alert-casemanagement-apim-failures-dev                  True       1
alert-casemanagement-app-errors-dev                     True       1
alert-casemanagement-resource-delete-dev                True       0
alert-casemanagement-security-policy-dev                True       0
```

## Step 5: Test Alerts

### Test Email Notification

```powershell
# Trigger a test alert
az monitor metrics alert create `
  --name test-alert `
  --resource-group rg-casemanagement-dev `
  --condition "avg Percentage CPU > 0" `
  --window-size 5m `
  --evaluation-frequency 1m `
  --action <action-group-id>

# You should receive an email within 5 minutes
```

### Simulate Backend Error

```powershell
# Make a request to a non-existent endpoint
curl https://your-container-app-url.azurecontainerapps.io/api/nonexistent
```

Check logs to see if the error is captured:

```powershell
az monitor log-analytics query `
  --workspace <workspace-id> `
  --analytics-query "ContainerAppConsoleLogs_CL | where Log_s contains 'ERROR' | take 10"
```

## What You Get

✅ **13 pre-configured alerts** based on Azure Monitor Baseline Alerts (AMBA)
✅ **2 action groups** (Critical and Warning)
✅ **Email notifications** for all alerts
✅ **Activity log monitoring** for security events
✅ **Log-based alerts** for application errors
✅ **Zero additional cost** for basic setup (within free tiers)

## View Your Alerts

### Azure Portal
1. Go to https://portal.azure.com
2. Navigate to **Monitor** → **Alerts**
3. Filter by your resource group

### Create Dashboard
1. Go to **Dashboard** → **+ New dashboard**
2. Name it "Case Management - Monitoring"
3. Add these tiles:
   - **Metric chart**: Container App CPU
   - **Metric chart**: PostgreSQL Storage
   - **Alerts**: Recent alerts
   - **Logs**: Error count

## Customize

### Change Email Recipients

Edit the `alertEmails` parameter in main.bicep:

```bicep
alertEmails: [
  'admin@company.com'
  'devops@company.com'
  'oncall@company.com'
]
```

### Add SMS Notifications

Edit `modules/monitoring.bicep` and add to the action group:

```bicep
smsReceivers: [
  {
    name: 'OnCall'
    countryCode: '1'  // USA
    phoneNumber: '5551234567'
  }
]
```

### Add Teams/Slack Integration

See [MONITORING_GUIDE.md](./MONITORING_GUIDE.md#integration-with-teamsslack) for webhook setup.

## Next Steps

1. ✅ Review [MONITORING_GUIDE.md](./MONITORING_GUIDE.md) for detailed information
2. ⬜ Set up custom dashboard
3. ⬜ Configure Teams/Slack webhooks
4. ⬜ Document incident response procedures
5. ⬜ Set up weekly alert review meetings

## Troubleshooting

### No emails received

```powershell
# Check action group status
az monitor action-group show `
  --resource-group rg-casemanagement-dev `
  --name ag-casemanagement-critical-dev `
  --query "{Name:name, Enabled:enabled, Emails:emailReceivers}"
```

### Alert not firing

```powershell
# Check if metric data exists
az monitor metrics list `
  --resource <container-app-id> `
  --metric-names UsageNanoCores `
  --start-time 2025-10-28T00:00:00Z `
  --end-time 2025-10-28T23:59:59Z
```

## Cost

For a dev environment with moderate traffic:

- **Month 1-3**: ~$0-$10 (free tier covers most usage)
- **After 3 months**: ~$50-$100/month (depends on log volume)

You can reduce costs by:
- Setting shorter retention periods (7-30 days)
- Disabling verbose logging
- Using log sampling

## Support

- 📚 [Full Monitoring Guide](./MONITORING_GUIDE.md)
- 📚 [AMBA Documentation](https://azure.github.io/azure-monitor-baseline-alerts/)
- 💬 Create an issue in this repo
- 💬 Azure support portal

---

**Ready to deploy?** Run the commands in Step 3 above! 🚀
