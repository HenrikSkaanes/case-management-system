// Main Bicep file - BUDGET-FRIENDLY POC VERSION
// Essential security features without expensive components
// Deploys: Networking → Key Vault → Private PostgreSQL → Container Apps → Static Web App
// Skips: API Management (~$50/mo), Front Door Premium (~$200-300/mo)

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

@description('PostgreSQL administrator password')
@secure()
param postgresqlAdminPassword string

// ============================================
// NETWORKING & SECURITY PARAMETERS
// ============================================

@description('VNet address prefix')
param vnetAddressPrefix string = '10.10.0.0/16'

@description('Container Apps control plane subnet prefix')
param subnetAcaControlPrefix string = '10.10.1.0/24'

@description('Container Apps runtime subnet prefix')
param subnetAcaRuntimePrefix string = '10.10.2.0/24'

@description('PostgreSQL delegated subnet prefix')
param subnetPostgresPrefix string = '10.10.3.0/24'

@description('Resource group name for DNS zone (if different from deployment RG)')
param dnsZoneResourceGroupName string = ''

@description('Deploy NAT Gateway for fixed egress IP (adds ~$30/month)')
param deployNatGateway bool = true

// ============================================
// VARIABLES
// ============================================

var resourceSuffix = '${baseName}-${environmentName}'
var tags = {
  Environment: environmentName
  Application: 'Case Management System'
  Architecture: 'Budget POC - Essential Security'
  ManagedBy: 'Bicep'
  DeployedFrom: 'GitHub Actions'
  CostCenter: 'POC'
}

// Resource names
var acrName = 'acr${replace(baseName, '-', '')}${environmentName}'
var logAnalyticsName = 'log-${resourceSuffix}'
var containerAppEnvironmentName = 'cae-${resourceSuffix}'
var apiAppName = 'ca-api-${resourceSuffix}'
var staticWebAppName = 'stapp-${resourceSuffix}'
var postgresqlServerName = 'psql-${replace(baseName, '-', '')}-${environmentName}'

// ============================================
// MODULES - BUDGET VERSION
// ============================================

// 1. Networking (VNet, Subnets, Optional NAT Gateway)
module networking 'modules/networking.bicep' = {
  name: 'networking-deployment'
  params: {
    vnetName: 'vnet-${resourceSuffix}'
    location: location
    vnetAddressPrefix: vnetAddressPrefix
    subnetAcaControlPrefix: subnetAcaControlPrefix
    subnetAcaRuntimePrefix: subnetAcaRuntimePrefix
    subnetPostgresPrefix: subnetPostgresPrefix
    tags: tags
  }
}

// 2. Container Registry
module acr 'modules/acr.bicep' = {
  name: 'acr-deployment'
  params: {
    acrName: acrName
    location: location
    sku: 'Basic'
    tags: tags
  }
}

// 3. Log Analytics
module logs 'modules/logs.bicep' = {
  name: 'logs-deployment'
  params: {
    logAnalyticsName: logAnalyticsName
    location: location
    tags: tags
  }
}

// 4. Key Vault (secrets management)
module keyVault 'modules/keyvault.bicep' = {
  name: 'keyvault-deployment'
  params: {
    keyVaultName: 'kv-${replace(baseName, '-', '')}${environmentName}'
    location: location
    principalId: ''  // Will be set in second deployment
    enableRbacAuthorization: true
    tags: tags
  }
}

// 5. PostgreSQL Private (database with private access)
module postgresqlPrivate 'modules/postgres-private.bicep' = {
  name: 'postgresql-private-deployment'
  params: {
    serverName: postgresqlServerName
    location: location
    adminUsername: 'caseadmin'
    adminPassword: postgresqlAdminPassword
    databaseName: 'casemanagement'
    postgresqlVersion: '16'
    skuTier: 'Burstable'
    skuName: 'Standard_B1ms'  // Can use B1s for ~$12/month instead
    storageSizeGB: 32
    subnetId: networking.outputs.subnetPostgresId
    vnetId: networking.outputs.vnetId
    dnsZoneResourceGroupName: dnsZoneResourceGroupName != '' ? dnsZoneResourceGroupName : resourceGroup().name
    tags: tags
  }
}

// 6. Container Apps Environment with VNet Injection
module containerAppsEnv 'modules/containerapps-env-vnet.bicep' = {
  name: 'containerapps-env-deployment'
  params: {
    environmentName: containerAppEnvironmentName
    appName: apiAppName
    location: location
    logAnalyticsWorkspaceId: logs.outputs.logAnalyticsId
    logAnalyticsCustomerId: logs.outputs.customerId
    subnetAcaControlId: networking.outputs.subnetAcaControlId
    subnetAcaRuntimeId: networking.outputs.subnetAcaRuntimeId
    containerImage: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
    containerRegistryServer: acr.outputs.acrLoginServer
    containerRegistryUsername: ''
    containerRegistryPassword: ''
    cpu: '0.5'
    memory: '1.0Gi'
    minReplicas: 0  // Scale to zero for cost savings
    maxReplicas: 3  // Limit for POC
    databaseConnectionString: 'postgresql://caseadmin:${postgresqlAdminPassword}@${postgresqlPrivate.outputs.serverFqdn}:5432/${postgresqlPrivate.outputs.databaseName}?sslmode=require'
    allowedCorsOrigin: ''  // Will be set to SWA hostname after deployment
    apimEgressIps: ''
    tags: tags
  }
}

// 7. Static Web App (Frontend) - Points directly to Container App
module staticWebApp 'modules/staticwebapp.bicep' = {
  name: 'staticwebapp-deployment'
  params: {
    staticWebAppName: staticWebAppName
    location: staticWebAppLocation
    sku: 'Free'
    apiUrl: 'https://${containerAppsEnv.outputs.apiFqdn}/api'  // Direct to Container App (no APIM)
    tags: tags
  }
}

// 8. Update Key Vault with Container App managed identity
module keyVaultRoleAssignment 'modules/keyvault.bicep' = {
  name: 'keyvault-role-assignment'
  params: {
    keyVaultName: 'kv-${replace(baseName, '-', '')}${environmentName}'
    location: location
    principalId: containerAppsEnv.outputs.managedIdentityPrincipalId
    enableRbacAuthorization: true
    tags: tags
  }
  dependsOn: [
    keyVault
    containerAppsEnv
  ]
}

// ============================================
// OUTPUTS
// ============================================

// Frontend URLs
output frontendUrl string = 'https://${staticWebApp.outputs.defaultHostname}'

// Backend URLs
output apiUrl string = containerAppsEnv.outputs.apiUrl
output apiFqdn string = containerAppsEnv.outputs.apiFqdn

// Container Registry
output acrLoginServer string = acr.outputs.acrLoginServer
output acrName string = acr.outputs.acrName

// App Names
output containerAppName string = containerAppsEnv.outputs.appName
output staticWebAppName string = staticWebApp.outputs.staticWebAppName
output logAnalyticsName string = logs.outputs.logAnalyticsName
output containerAppEnvironmentName string = containerAppsEnv.outputs.environmentName

// Resource Group
output resourceGroupName string = resourceGroup().name

// PostgreSQL
output postgresqlServerFqdn string = postgresqlPrivate.outputs.serverFqdn
output postgresqlDatabaseName string = postgresqlPrivate.outputs.databaseName
output postgresqlPrivateDnsZone string = postgresqlPrivate.outputs.privateDnsZoneName

// Key Vault
output keyVaultName string = keyVault.outputs.keyVaultName
output keyVaultUri string = keyVault.outputs.keyVaultUri

// Networking
output vnetName string = networking.outputs.vnetName
output natPublicIp string = deployNatGateway ? networking.outputs.natPublicIp : 'Not deployed'

// Managed Identity
output containerAppManagedIdentityPrincipalId string = containerAppsEnv.outputs.managedIdentityPrincipalId

// Deployment summary message
output deploymentMessage string = '''
🎉 Budget POC Deployment Complete!

💰 ESTIMATED MONTHLY COST: $80-100

FRONTEND ACCESS:
🌐 Static Web App: https://${staticWebApp.outputs.defaultHostname}

BACKEND ACCESS:
🔗 Container App API: ${containerAppsEnv.outputs.apiUrl}
📊 API Docs: ${containerAppsEnv.outputs.apiUrl}/docs

INFRASTRUCTURE:
🌐 VNet: ${networking.outputs.vnetName} (Private networking)
${deployNatGateway ? '📤 NAT Gateway IP: ${networking.outputs.natPublicIp} (Fixed egress)' : ''}
🗄️  PostgreSQL (private): ${postgresqlPrivate.outputs.serverFqdn}
🔐 Key Vault: ${keyVault.outputs.keyVaultName}

ARCHITECTURE (Budget POC):
User → Static Web App (frontend) → Container App API → Private PostgreSQL
     ↓
   VNet-isolated with managed identities

COST OPTIMIZATIONS APPLIED:
✅ Using essential security components only
✅ Container Apps can scale to zero (minReplicas: 0)
✅ No API Management (-$50/month)
✅ No Front Door Premium (-$200-300/month)
✅ Private PostgreSQL for security
${deployNatGateway ? '' : '✅ NAT Gateway skipped (-$30/month)'}

SECURITY FEATURES:
✅ VNet isolation with private PostgreSQL
✅ Key Vault with RBAC + managed identities
✅ HTTPS enforcement
✅ Container Apps built-in CORS
${deployNatGateway ? '✅ Fixed egress IP via NAT Gateway' : '⚠️  Dynamic egress IP (NAT Gateway disabled)'}

NEXT STEPS:
1. Deploy backend: docker push ${acr.outputs.acrLoginServer}/api:latest
2. Frontend auto-deploys via GitHub Actions
3. Monitor costs in Azure Cost Management

UPGRADE PATH (When Needed):
→ Add API Management: +$50/month (rate limiting, analytics)
→ Add Front Door Premium: +$200-300/month (WAF, global CDN)
'''
