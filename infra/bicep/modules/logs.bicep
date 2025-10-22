// Log Analytics Workspace
// Collects logs and metrics from Container Apps

@description('Name of the Log Analytics workspace')
param logAnalyticsName string

@description('Location for the workspace')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

// Create Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018' // Pay-as-you-go pricing
    }
    retentionInDays: 30 // Keep logs for 30 days
  }
}

// Outputs
output logAnalyticsId string = logAnalytics.id
output logAnalyticsName string = logAnalytics.name
output customerId string = logAnalytics.properties.customerId
// Note: Shared key NOT output to avoid "content already consumed" error
// Environment module will call listKeys() directly on existing resource
