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

@description('PostgreSQL administrator password')
@secure()
param postgresqlAdminPassword string

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
var apiAppName = 'ca-api-${resourceSuffix}'
var staticWebAppName = 'stapp-${resourceSuffix}'
var postgresqlServerName = 'psql-${replace(baseName, '-', '')}-${environmentName}'
var communicationServicesName = 'acs-${resourceSuffix}'
var emailServiceName = 'email-${resourceSuffix}'

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

// Create Container App Environment
module environment 'modules/environment.bicep' = {
  name: 'environment-deployment'
  params: {
    environmentName: environmentName
    location: location
    tags: tags
  }
  dependsOn: [
    logs
  ]
}

// 4. PostgreSQL Database (persistent storage)
module postgresql 'modules/postgresql.bicep' = {
  name: 'postgresql-deployment'
  params: {
    serverName: postgresqlServerName
    location: location
    adminUsername: 'caseadmin'
    adminPassword: postgresqlAdminPassword
    databaseName: 'casemanagement'
    postgresqlVersion: '16'
    skuTier: 'Burstable'
    skuName: 'Standard_B1ms'  // ~$25/month
    storageSizeGB: 32
    tags: tags
  }
}

// 5. Azure Communication Services (email capabilities)
// TEMPORARILY DISABLED to isolate deployment error
/*
module communicationServices 'modules/communication-services.bicep' = {
  name: 'communication-services-deployment'
  params: {
    communicationServicesName: communicationServicesName
    emailServiceName: emailServiceName
    location: 'global'
    emailServiceLocation: 'westeurope'  // Closest to Norway
    domainName: 'AzureManagedDomain'  // Free managed domain
    tags: tags
  }
}
*/

// 6. Container App (Backend API only - NO frontend)
module apiApp 'modules/app.bicep' = {
  name: 'api-app-deployment'
  params: {
    appName: apiAppName
    location: location
    environmentId: environment.outputs.environmentId
    acrLoginServer: acr.outputs.acrLoginServer
    imageName: 'api:${imageTag}'
    usePublicImage: true // Use placeholder on first deploy
  acrUsername: ''
  acrPassword: ''
    cpu: '0.25'  // Smaller since no frontend
    memory: '0.5Gi'  // Smaller since no frontend
    minReplicas: 1
    maxReplicas: 5  // Can scale higher now
    databaseConnectionString: 'postgresql://caseadmin:${postgresqlAdminPassword}@${postgresql.outputs.serverFqdn}:5432/${postgresql.outputs.databaseName}?sslmode=require'
    acsConnectionString: ''  // Will be configured via Azure CLI after deployment (see docs/GET_SENDER_EMAIL.md)
    acsSenderEmail: 'placeholder@example.com'  // communicationServices.outputs.senderEmail
    companyName: 'Wrangler Tax Services'
    tags: tags
  }
}

// 7. Static Web App (Frontend on CDN)
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
// Note: deploymentToken NOT output - retrieve via Azure CLI to avoid "content already consumed" error
output resourceGroupName string = resourceGroup().name

// PostgreSQL outputs
output postgresqlServerFqdn string = postgresql.outputs.serverFqdn
output postgresqlDatabaseName string = postgresql.outputs.databaseName

// Azure Communication Services outputs
// TEMPORARILY DISABLED
/*
output acsServiceName string = communicationServices.outputs.communicationServiceName
output acsServiceId string = communicationServices.outputs.communicationServiceId
output acsSenderEmail string = communicationServices.outputs.senderEmail
*/

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

DATABASE (PostgreSQL Flexible Server):
🗄️  Server: ${postgresql.outputs.serverFqdn}
📦 Database: ${postgresql.outputs.databaseName}
🔐 Connection: Use DATABASE_URL secret in backend

EMAIL SERVICES (Azure Communication Services):
📧 Sender Email: ${communicationServices.outputs.senderEmail} (placeholder)
🔗 Service: ${communicationServices.outputs.communicationServiceName}
💵 Cost: ~$0.00025 per email sent

⚠️  POST-DEPLOYMENT REQUIRED:
Configure ACS connection string and sender email:
1. See docs/GET_SENDER_EMAIL.md for instructions
2. Run: az containerapp update to set ACS_CONNECTION_STRING
3. Get real sender email from Azure Portal

Container Registry: ${acr.outputs.acrLoginServer}

To deploy backend:
1. docker build -t ${acr.outputs.acrLoginServer}/api:latest backend/
2. docker push ${acr.outputs.acrLoginServer}/api:latest

Frontend deploys automatically via GitHub Actions!
'''
