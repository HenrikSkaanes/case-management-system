// Azure Container Registry (ACR)
// Stores Docker images privately

@description('Name of the Container Registry')
param acrName string

@description('Location for the registry')
param location string = resourceGroup().location

@description('SKU tier (Basic, Standard, Premium)')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

@description('Tags to apply to resources')
param tags object = {}

// Create Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: true // Needed for GitHub Actions to push images
    publicNetworkAccess: 'Enabled'
  }
}

// Outputs that other modules can use
output acrLoginServer string = containerRegistry.properties.loginServer
output acrName string = containerRegistry.name
output acrId string = containerRegistry.id
