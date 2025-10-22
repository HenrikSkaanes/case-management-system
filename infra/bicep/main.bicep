// Main Bicep file - Orchestrates all modules
// Deploys: ACR → Logs → Environment → Container App

targetScope = 'resourceGroup'

// ============================================
// PARAMETERS
// ============================================

@description('Base name for all resources (will be prefixed/suffixed)')
param baseName string = 'casemanagement'

@description('Environment name (dev, test, prod)')
@allowed([
  'dev'
  'test'
  'prod'
])
param environmentName string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Container image tag to deploy')
param imageTag string = 'latest'

// ============================================
// VARIABLES
// ============================================

var resourceSuffix = '${baseName}-${environmentName}'
var tags = {
  Environment: environmentName
  Application: 'Case Management System'
  ManagedBy: 'Bicep'
  DeployedFrom: 'GitHub Actions'
}

// Resource names (following Azure naming conventions)
var acrName = 'acr${replace(baseName, '-', '')}${environmentName}' // ACR names can't have dashes
var logAnalyticsName = 'log-${resourceSuffix}'
var environmentResourceName = 'cae-${resourceSuffix}'
var appName = 'ca-${resourceSuffix}'

// ============================================
// MODULES
// ============================================

// 1. Container Registry (stores Docker images)
module acr 'modules/acr.bicep' = {
  name: 'acr-deployment'
  params: {
    acrName: acrName
    location: location
    sku: 'Basic' // Basic is cheapest, sufficient for small projects
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

// 3. Container App Environment (runtime infrastructure)
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

// 4. Container App (your application)
module app 'modules/app.bicep' = {
  name: 'app-deployment'
  params: {
    appName: appName
    location: location
    environmentId: environment.outputs.environmentId
    acrLoginServer: acr.outputs.acrLoginServer
    acrName: acr.outputs.acrName
    imageName: 'case-management:${imageTag}'
    usePublicImage: true // Use placeholder image on first deploy
    cpu: '0.5'
    memory: '1.0Gi'
    minReplicas: 1
    maxReplicas: 3
    tags: tags
  }
}

// ============================================
// OUTPUTS (displayed after deployment)
// ============================================

output applicationUrl string = app.outputs.appUrl
output acrLoginServer string = acr.outputs.acrLoginServer
output acrName string = acr.outputs.acrName
output containerAppName string = app.outputs.appName
output resourceGroupName string = resourceGroup().name

// Display a success message with the URL
output deploymentMessage string = '''
🎉 Deployment Complete!

Your Case Management System is now live at:
${app.outputs.appUrl}

Container Registry: ${acr.outputs.acrLoginServer}
Container App: ${app.outputs.appName}

To push a new Docker image:
1. docker tag case-management:latest ${acr.outputs.acrLoginServer}/case-management:latest
2. docker push ${acr.outputs.acrLoginServer}/case-management:latest
'''
