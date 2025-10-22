// Main Bicep file - Separated Frontend (Static Web App) + Backend (Container App)
// Deploys: ACR → Logs → Environment → Backend API → Frontend

targetScope = 'resourceGroup'

// ============================================
// PARAMETERS
// ============================================

@description('Base name for all resources')
param baseName string = 'casemanagement'

@description('Environment name (dev, test, prod)')
@allowed([
  'dev'
  'test'
  'prod'
])
param environmentName string = 'dev'

@description('Location for Container App resources')
param location string = resourceGroup().location

@description('Location for Static Web App (limited regions)')
param staticWebAppLocation string = 'westeurope'

@description('Container image tag to deploy')
param imageTag string = 'latest'

// ============================================
// VARIABLES
// ============================================

var resourceSuffix = '${baseName}-${environmentName}'
var tags = {
  Environment: environmentName
  Application: 'Case Management System'
  Architecture: 'Static Web App + Container App API'
  ManagedBy: 'Bicep'
  DeployedFrom: 'GitHub Actions'
}

// Resource names
var acrName = 'acr${replace(baseName, '-', '')}${environmentName}'
var logAnalyticsName = 'log-${resourceSuffix}'
var environmentResourceName = 'cae-${resourceSuffix}'
var apiAppName = 'ca-api-${resourceSuffix}'
var staticWebAppName = 'stapp-${resourceSuffix}'

// ============================================
// MODULES
// ============================================

// 1. Container Registry (stores Docker images)
module acr 'modules/acr.bicep' = {
  name: 'acr-deployment'
  params: {
    acrName: acrName
    location: location
    sku: 'Basic'
    tags: tags
  }
}

// 2. Log Analytics (monitoring and logs)
module logs 'modules/logs.bicep' = {
  name: 'logs-deployment'
  params: {
    logAnalyticsName: logAnalyticsName
    location: location
    tags: tags
  }
}

// 3. Container App Environment (runtime infrastructure for backend)
module environment 'modules/environment.bicep' = {
  name: 'environment-deployment'
  params: {
    environmentName: environmentResourceName
    location: location
    logAnalyticsId: logs.outputs.logAnalyticsId
    logAnalyticsCustomerId: logs.outputs.customerId
    tags: tags
  }
}

// 4. Container App (Backend API only - NO frontend)
module apiApp 'modules/app.bicep' = {
  name: 'api-app-deployment'
  params: {
    appName: apiAppName
    location: location
    environmentId: environment.outputs.environmentId
    acrLoginServer: acr.outputs.acrLoginServer
    acrName: acr.outputs.acrName
    imageName: 'api:${imageTag}'
    usePublicImage: true // Use placeholder on first deploy
    cpu: '0.25'  // Smaller since no frontend
    memory: '0.5Gi'  // Smaller since no frontend
    minReplicas: 1
    maxReplicas: 5  // Can scale higher now
    tags: tags
  }
}

// 5. Static Web App (Frontend on CDN)
module staticWebApp 'modules/staticwebapp.bicep' = {
  name: 'staticwebapp-deployment'
  params: {
    staticWebAppName: staticWebAppName
    location: staticWebAppLocation
    sku: 'Free'  // Free tier is perfect for this!
    apiUrl: 'https://${apiApp.outputs.fqdn}/api'  // Point frontend to backend API
    tags: tags
  }
}

// ============================================
// OUTPUTS
// ============================================

output frontendUrl string = 'https://${staticWebApp.outputs.defaultHostname}'
output apiUrl string = 'https://${apiApp.outputs.fqdn}'
output acrLoginServer string = acr.outputs.acrLoginServer
output acrName string = acr.outputs.acrName
output apiAppName string = apiApp.outputs.appName
output staticWebAppName string = staticWebApp.outputs.staticWebAppName
output staticWebAppDeploymentToken string = staticWebApp.outputs.deploymentToken
output resourceGroupName string = resourceGroup().name

// Deployment summary message
output deploymentMessage string = '''
🎉 Deployment Complete!

FRONTEND (Static Web App - on Global CDN):
🌐 URL: https://${staticWebApp.outputs.defaultHostname}
📦 Deploy via GitHub Actions with deployment token

BACKEND (Container App API):
🔗 API URL: https://${apiApp.outputs.fqdn}
📊 API Docs: https://${apiApp.outputs.fqdn}/docs
🏥 Health: https://${apiApp.outputs.fqdn}/health

Container Registry: ${acr.outputs.acrLoginServer}

To deploy backend:
1. docker build -t ${acr.outputs.acrLoginServer}/api:latest backend/
2. docker push ${acr.outputs.acrLoginServer}/api:latest

Frontend deploys automatically via GitHub Actions!
'''
