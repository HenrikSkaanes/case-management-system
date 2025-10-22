// Azure Static Web App
// Hosts the React frontend on global CDN

@description('Name of the Static Web App')
param staticWebAppName string

@description('Location for the Static Web App')
param location string = 'westeurope' // Static Web Apps limited regions

@description('SKU tier (Free or Standard)')
@allowed([
  'Free'
  'Standard'
])
param sku string = 'Free'

@description('Tags to apply to resources')
param tags object = {}

@description('Backend API URL for the frontend to call')
param apiUrl string = ''

// Create Static Web App
resource staticWebApp 'Microsoft.Web/staticSites@2023-01-01' = {
  name: staticWebAppName
  location: location
  tags: tags
  sku: {
    name: sku
    tier: sku
  }
  properties: {
    repositoryUrl: '' // Set via GitHub Actions
    branch: '' // Set via GitHub Actions
    buildProperties: {
      appLocation: 'frontend'
      apiLocation: '' // No built-in API functions
      outputLocation: 'dist'
    }
    stagingEnvironmentPolicy: 'Enabled'
    allowConfigFileUpdates: true
  }
}

// Configure app settings (environment variables for the frontend)
resource appSettings 'Microsoft.Web/staticSites/config@2023-01-01' = if (apiUrl != '') {
  parent: staticWebApp
  name: 'appsettings'
  properties: {
    VITE_API_URL: apiUrl
  }
}

// Outputs
output staticWebAppId string = staticWebApp.id
output staticWebAppName string = staticWebApp.name
output defaultHostname string = staticWebApp.properties.defaultHostname
output deploymentToken string = listSecrets(staticWebApp.id, '2023-01-01').properties.apiKey
