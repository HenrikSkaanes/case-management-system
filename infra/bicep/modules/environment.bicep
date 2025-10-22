// Container App Environment
// Provides the runtime environment for Container Apps (like a "cluster")

@description('Name of the Container App Environment')
param environmentName string

@description('Location for the environment')
param location string = resourceGroup().location

@description('Log Analytics workspace ID for monitoring')
param logAnalyticsId string

@description('Log Analytics customer ID')
param logAnalyticsCustomerId string

@description('Log Analytics workspace name')
param logAnalyticsWorkspaceName string

@description('Tags to apply to resources')
param tags object = {}

// Reference existing Log Analytics workspace to get shared key
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}

// Create Container App Environment
resource environment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: environmentName
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsCustomerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

// Outputs
output environmentId string = environment.id
output environmentName string = environment.name
output defaultDomain string = environment.properties.defaultDomain
