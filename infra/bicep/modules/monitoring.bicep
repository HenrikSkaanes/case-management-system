// Comprehensive Monitoring Setup
// Based on Azure Monitor Baseline Alerts (AMBA) recommendations
// Uses Azure Verified Modules where applicable

targetScope = 'resourceGroup'

@description('Base name for monitoring resources')
param baseName string

@description('Environment name (dev, test, prod)')
param environmentName string

@description('Location for resources')
param location string = resourceGroup().location

@description('Log Analytics Workspace ID')
param logAnalyticsWorkspaceId string

@description('Container App resource ID')
param containerAppId string

@description('PostgreSQL Server resource ID')
param postgresqlServerId string

@description('API Management resource ID')
param apimId string

@description('Email addresses to receive alerts')
param alertEmails array = []

@description('Tags to apply to resources')
param tags object = {}

// ============================================
// ACTION GROUPS (Notification Channels)
// ============================================

// Critical alerts action group (immediate notification)
resource criticalActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-${baseName}-critical-${environmentName}'
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'CritAlerts'
    enabled: true
    emailReceivers: [for (email, i) in alertEmails: {
      name: 'Email${i}'
      emailAddress: email
      useCommonAlertSchema: true
    }]
    // Add SMS receivers if needed
    // smsReceivers: []
    // webhookReceivers: [] // Can integrate with Teams, Slack, PagerDuty
  }
}

// Warning alerts action group (less urgent)
resource warningActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-${baseName}-warning-${environmentName}'
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'WarnAlerts'
    enabled: true
    emailReceivers: [for (email, i) in alertEmails: {
      name: 'Email${i}'
      emailAddress: email
      useCommonAlertSchema: true
    }]
  }
}

// ============================================
// CONTAINER APP ALERTS (Backend API)
// ============================================

// Alert: High CPU Usage (AMBA recommendation: 90%)
resource containerAppCpuAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${baseName}-containerapp-cpu-${environmentName}'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when Container App CPU usage exceeds 90%'
    severity: 2 // Warning
    enabled: true
    scopes: [containerAppId]
    evaluationFrequency: 'PT5M' // Check every 5 minutes
    windowSize: 'PT15M' // Look at 15 minute window
    targetResourceType: 'Microsoft.App/containerApps'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighCPUUsage'
          metricName: 'UsageNanoCores'
          metricNamespace: 'Microsoft.App/containerApps'
          operator: 'GreaterThan'
          threshold: 900000000 // 90% of 1 core (in nanocores)
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: warningActionGroup.id
      }
    ]
  }
}

// Alert: High Memory Usage (AMBA recommendation: 90%)
resource containerAppMemoryAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${baseName}-containerapp-memory-${environmentName}'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when Container App memory usage exceeds 90%'
    severity: 2
    enabled: true
    scopes: [containerAppId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    targetResourceType: 'Microsoft.App/containerApps'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighMemoryUsage'
          metricName: 'WorkingSetBytes'
          metricNamespace: 'Microsoft.App/containerApps'
          operator: 'GreaterThan'
          threshold: 943718400 // 90% of 1GB
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: warningActionGroup.id
      }
    ]
  }
}

// Alert: Container App Restart Count
resource containerAppRestartAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${baseName}-containerapp-restarts-${environmentName}'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when Container App restarts frequently'
    severity: 1 // High
    enabled: true
    scopes: [containerAppId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    targetResourceType: 'Microsoft.App/containerApps'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'FrequentRestarts'
          metricName: 'Restarts'
          metricNamespace: 'Microsoft.App/containerApps'
          operator: 'GreaterThan'
          threshold: 3 // More than 3 restarts in 15 minutes
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: criticalActionGroup.id
      }
    ]
  }
}

// Alert: HTTP 5xx Errors (Backend failures)
resource containerAppHttp5xxAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${baseName}-containerapp-http5xx-${environmentName}'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when Container App has high rate of 5xx errors'
    severity: 1
    enabled: true
    scopes: [containerAppId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    targetResourceType: 'Microsoft.App/containerApps'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'High5xxErrors'
          metricName: 'Requests'
          metricNamespace: 'Microsoft.App/containerApps'
          operator: 'GreaterThan'
          threshold: 10 // More than 10 5xx errors
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
          dimensions: [
            {
              name: 'statusCodeCategory'
              operator: 'Include'
              values: ['5xx']
            }
          ]
        }
      ]
    }
    actions: [
      {
        actionGroupId: criticalActionGroup.id
      }
    ]
  }
}

// ============================================
// POSTGRESQL ALERTS
// ============================================

// Alert: High CPU (AMBA recommendation: 90%)
resource postgresqlCpuAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${baseName}-postgresql-cpu-${environmentName}'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when PostgreSQL CPU usage exceeds 90%'
    severity: 2
    enabled: true
    scopes: [postgresqlServerId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    targetResourceType: 'Microsoft.DBforPostgreSQL/flexibleServers'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighCPU'
          metricName: 'cpu_percent'
          metricNamespace: 'Microsoft.DBforPostgreSQL/flexibleServers'
          operator: 'GreaterThan'
          threshold: 90
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: warningActionGroup.id
      }
    ]
  }
}

// Alert: High Memory (AMBA recommendation: 90%)
resource postgresqlMemoryAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${baseName}-postgresql-memory-${environmentName}'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when PostgreSQL memory usage exceeds 90%'
    severity: 2
    enabled: true
    scopes: [postgresqlServerId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    targetResourceType: 'Microsoft.DBforPostgreSQL/flexibleServers'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighMemory'
          metricName: 'memory_percent'
          metricNamespace: 'Microsoft.DBforPostgreSQL/flexibleServers'
          operator: 'GreaterThan'
          threshold: 90
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: warningActionGroup.id
      }
    ]
  }
}

// Alert: Storage almost full (AMBA recommendation: 85%)
resource postgresqlStorageAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${baseName}-postgresql-storage-${environmentName}'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when PostgreSQL storage usage exceeds 85%'
    severity: 1
    enabled: true
    scopes: [postgresqlServerId]
    evaluationFrequency: 'PT15M'
    windowSize: 'PT1H'
    targetResourceType: 'Microsoft.DBforPostgreSQL/flexibleServers'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighStorage'
          metricName: 'storage_percent'
          metricNamespace: 'Microsoft.DBforPostgreSQL/flexibleServers'
          operator: 'GreaterThan'
          threshold: 85
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: criticalActionGroup.id
      }
    ]
  }
}

// Alert: Connection failures
resource postgresqlConnectionAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${baseName}-postgresql-connections-${environmentName}'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when PostgreSQL has failed connections'
    severity: 1
    enabled: true
    scopes: [postgresqlServerId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    targetResourceType: 'Microsoft.DBforPostgreSQL/flexibleServers'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'FailedConnections'
          metricName: 'connections_failed'
          metricNamespace: 'Microsoft.DBforPostgreSQL/flexibleServers'
          operator: 'GreaterThan'
          threshold: 5
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: criticalActionGroup.id
      }
    ]
  }
}

// ============================================
// API MANAGEMENT ALERTS
// ============================================

// Alert: High latency (AMBA recommendation: track 95th percentile)
resource apimLatencyAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${baseName}-apim-latency-${environmentName}'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when APIM request latency is high'
    severity: 2
    enabled: true
    scopes: [apimId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    targetResourceType: 'Microsoft.ApiManagement/service'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighLatency'
          metricName: 'Duration'
          metricNamespace: 'Microsoft.ApiManagement/service'
          operator: 'GreaterThan'
          threshold: 5000 // 5 seconds
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: warningActionGroup.id
      }
    ]
  }
}

// Alert: Failed requests
resource apimFailureAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${baseName}-apim-failures-${environmentName}'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when APIM has high rate of failed requests'
    severity: 1
    enabled: true
    scopes: [apimId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    targetResourceType: 'Microsoft.ApiManagement/service'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighFailureRate'
          metricName: 'FailedRequests'
          metricNamespace: 'Microsoft.ApiManagement/service'
          operator: 'GreaterThan'
          threshold: 10
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: criticalActionGroup.id
      }
    ]
  }
}

// ============================================
// LOG-BASED ALERTS (KQL Queries)
// ============================================

// Alert: Application errors in logs
resource appErrorsAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'alert-${baseName}-app-errors-${environmentName}'
  location: location
  tags: tags
  properties: {
    displayName: 'Application Errors in Logs'
    description: 'Alert when application logs contain errors'
    severity: 1
    enabled: true
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    scopes: [logAnalyticsWorkspaceId]
    targetResourceTypes: ['Microsoft.OperationalInsights/workspaces']
    criteria: {
      allOf: [
        {
          query: '''
            ContainerAppConsoleLogs_CL
            | where Log_s contains "ERROR" or Log_s contains "Exception"
            | where TimeGenerated > ago(15m)
            | summarize ErrorCount = count() by bin(TimeGenerated, 5m)
            | where ErrorCount > 5
          '''
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [criticalActionGroup.id]
    }
  }
}

// ============================================
// ACTIVITY LOG ALERTS (Azure Resource Changes)
// ============================================

// Alert: When resources are deleted
resource resourceDeleteAlert 'Microsoft.Insights/activityLogAlerts@2020-10-01' = {
  name: 'alert-${baseName}-resource-delete-${environmentName}'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when resources are deleted'
    enabled: true
    scopes: [resourceGroup().id]
    condition: {
      allOf: [
        {
          field: 'category'
          equals: 'Administrative'
        }
        {
          field: 'operationName'
          equals: 'Microsoft.Resources/subscriptions/resourceGroups/delete'
        }
      ]
    }
    actions: {
      actionGroups: [
        {
          actionGroupId: criticalActionGroup.id
        }
      ]
    }
  }
}

// Alert: When security policies change
resource securityPolicyAlert 'Microsoft.Insights/activityLogAlerts@2020-10-01' = {
  name: 'alert-${baseName}-security-policy-${environmentName}'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when security-related configurations change'
    enabled: true
    scopes: [resourceGroup().id]
    condition: {
      allOf: [
        {
          field: 'category'
          equals: 'Security'
        }
      ]
    }
    actions: {
      actionGroups: [
        {
          actionGroupId: criticalActionGroup.id
        }
      ]
    }
  }
}

// ============================================
// OUTPUTS
// ============================================

output criticalActionGroupId string = criticalActionGroup.id
output warningActionGroupId string = warningActionGroup.id
output monitoringResourceIds array = [
  containerAppCpuAlert.id
  containerAppMemoryAlert.id
  containerAppRestartAlert.id
  containerAppHttp5xxAlert.id
  postgresqlCpuAlert.id
  postgresqlMemoryAlert.id
  postgresqlStorageAlert.id
  postgresqlConnectionAlert.id
  apimLatencyAlert.id
  apimFailureAlert.id
  appErrorsAlert.id
  resourceDeleteAlert.id
  securityPolicyAlert.id
]
