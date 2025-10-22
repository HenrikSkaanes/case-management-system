// Container App Environment
// Provides the runtime environment for Container Apps (like a "cluster")

@description('Name of the Container App Environment')
param environmentName string

@description('Location for the environment')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

// Create Container App Environment without Log Analytics (configure post-deployment)
// This avoids the "content already consumed" error from calling listKeys()
resource environment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: environmentName
  location: location
  tags: tags
  properties: {
    // Log Analytics will be configured via Azure CLI post-deployment
  }
}

// Outputs
output environmentId string = environment.id
output environmentName string = environment.name
output defaultDomain string = environment.properties.defaultDomain
