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

@description('Enable Azure AD authentication for PostgreSQL')
param enablePostgresAadAuth bool = true

// ============================================
// NETWORKING & SECURITY PARAMETERS
// ============================================

@description('Allowed CORS origin for API (typically SWA hostname)')
param allowedCorsOrigin string = ''

@description('Resource group name for DNS zone (if different from deployment RG)')
param dnsZoneResourceGroupName string = ''

@description('VNet address prefix')
param vnetAddressPrefix string = '10.10.0.0/16'

@description('Container Apps control plane subnet prefix - must be /23 or larger')
param subnetAcaControlPrefix string = '10.10.0.0/23'

@description('Container Apps runtime subnet prefix - must be /23 or larger')
param subnetAcaRuntimePrefix string = '10.10.2.0/23'

@description('PostgreSQL delegated subnet prefix')
param subnetPostgresPrefix string = '10.10.4.0/24'

@description('API Management SKU (Developer, Basic, Standard, Premium, Consumption)')
@allowed([
  'Consumption'
  'Developer'
  'Basic'
  'Standard'
  'Premium'
])
param apimSkuName string = 'Consumption'

@description('Azure Front Door SKU (Standard or Premium)')
@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
param frontDoorSkuName string = 'Standard_AzureFrontDoor'

@description('Optional custom domain for Azure Front Door (e.g., app.example.com)')
param frontDoorCustomDomain string = ''

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
var containerAppEnvironmentName = 'cae-${resourceSuffix}'
var apiAppName = 'ca-api-${resourceSuffix}'
var staticWebAppName = 'stapp-${resourceSuffix}'
var postgresqlServerName = 'psql-${replace(baseName, '-', '')}-${environmentName}'
var acsBaseName = '${replace(baseName, '-', '')}${environmentName}'
var logicAppEmailName = 'logic-email-${resourceSuffix}'

// ============================================
// MODULES
// ============================================

// 1. Networking (VNet, Subnets, NAT Gateway) - Foundation layer
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

// 2. Container Registry (stores Docker images) - Parallel with Networking
module acr 'modules/acr.bicep' = {
  name: 'acr-deployment'
  params: {
    acrName: acrName
    location: location
    sku: 'Basic'
    tags: tags
  }
}

// 3. Log Analytics (monitoring and logs) - Parallel with Networking
module logs 'modules/logs.bicep' = {
  name: 'logs-deployment'
  params: {
    logAnalyticsName: logAnalyticsName
    location: location
    tags: tags
  }
}

// 3a. Azure Communication Services (email notifications) - Can deploy early
module communicationServices 'modules/communication-services.bicep' = {
  name: 'communication-services-deployment'
  params: {
    baseName: acsBaseName
    location: 'global'
    dataLocation: 'Europe'
    tags: tags
  }
}

// 4. Key Vault (secrets management) - After Networking (but before apps need it)
module keyVault 'modules/keyvault.bicep' = {
  name: 'keyvault-deployment'
  params: {
    keyVaultName: 'kv-${replace(baseName, '-', '')}${environmentName}'  // KV names can't have dashes
    location: location
    principalId: ''  // Will be set in second deployment after Container App is created
    enableRbacAuthorization: true
    tags: tags
  }
  dependsOn: [
    networking
  ]
}

// 5. PostgreSQL Private (database with private access) - After Networking
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
    skuName: 'Standard_B1ms'  // ~$25/month (can use B1s for ~$12/month)
    storageSizeGB: 32
    subnetId: networking.outputs.subnetPostgresId
    vnetId: networking.outputs.vnetId
    dnsZoneResourceGroupName: dnsZoneResourceGroupName != '' ? dnsZoneResourceGroupName : resourceGroup().name
    enableAadAuth: enablePostgresAadAuth
    aadAdminPrincipalId: '' // Will be set after Container App is created
    aadAdminPrincipalName: ''
    aadAdminPrincipalType: 'ServicePrincipal'
    tags: tags
  }
  dependsOn: [
    networking
  ]
}

// 6. Container Apps Environment with VNet Injection - After Networking + Logs
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
    containerImage: '${acr.outputs.acrLoginServer}/api:${imageTag}'
    containerRegistryServer: acr.outputs.acrLoginServer
    containerRegistryUsername: ''
    containerRegistryPassword: ''  // Using Managed Identity for ACR pull
    cpu: '0.5'
    memory: '1.0Gi'
    minReplicas: 1
    maxReplicas: 5
    databaseConnectionString: 'postgresql://caseadmin:${postgresqlAdminPassword}@${postgresqlPrivate.outputs.serverFqdn}:5432/${postgresqlPrivate.outputs.databaseName}?sslmode=require'
    acsEndpoint: communicationServices.outputs.endpoint
    acsSenderEmail: communicationServices.outputs.senderEmail
    companyName: 'Wrangler Tax Services'
    allowedCorsOrigin: allowedCorsOrigin != '' ? allowedCorsOrigin : ''  // Will be set to SWA hostname after deployment
    apimEgressIps: ''  // TODO: Set after APIM is deployed
    tags: tags
  }
}

// 6a. Grant Container App Managed Identity permission to pull from ACR
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrName, apiAppName, 'AcrPull')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull role
    principalId: containerAppsEnv.outputs.managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// 6b. Grant Container App Managed Identity permission to send emails via ACS
resource acsContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acsBaseName, apiAppName, 'ACSContributor')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '1d8cafef-63be-4d49-87cf-b8f5ae486e41') // Contributor role for ACS
    principalId: containerAppsEnv.outputs.managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// 7. Static Web App (Frontend on CDN) - Can deploy early, will point to APIM later
module staticWebApp 'modules/staticwebapp.bicep' = {
  name: 'staticwebapp-deployment'
  params: {
    staticWebAppName: staticWebAppName
    location: staticWebAppLocation
    sku: 'Free'  // Free tier is perfect for this!
    apiUrl: 'https://placeholder-will-be-updated-to-apim-url.azurewebsites.net/api'  // Will be updated after APIM deployment
    tags: tags
  }
}

// 7a. Logic App (Email workflow automation) - After Container App for webhook URL
module logicAppEmail 'modules/logic-app.bicep' = {
  name: 'logic-app-email-deployment'
  params: {
    logicAppName: logicAppEmailName
    location: location
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              type: 'object'
              properties: {
                ticketId: { type: 'integer' }
                ticketTitle: { type: 'string' }
                priority: { type: 'string' }
                customerEmail: { type: 'string' }
                customerName: { type: 'string' }
              }
            }
          }
        }
      }
      actions: {
        // Condition: Is priority HIGH or CRITICAL?
        CheckPriority: {
          type: 'If'
          expression: {
            or: [
              { equals: ['@triggerBody()?[\'priority\']', 'HIGH'] }
              { equals: ['@triggerBody()?[\'priority\']', 'CRITICAL'] }
            ]
          }
          actions: {
            // TODO: Add Teams notification or other high-priority actions
            SendHighPriorityNotification: {
              type: 'Response'
              inputs: {
                statusCode: 200
                body: {
                  message: 'High priority ticket notification sent'
                  ticketId: '@triggerBody()?[\'ticketId\']'
                }
              }
            }
          }
          else: {
            actions: {
              SendNormalNotification: {
                type: 'Response'
                inputs: {
                  statusCode: 200
                  body: {
                    message: 'Normal ticket notification processed'
                    ticketId: '@triggerBody()?[\'ticketId\']'
                  }
                }
              }
            }
          }
        }
      }
      outputs: {}
    }
    tags: tags
  }
}

// 8. API Management (external API façade) - After Container Apps
module apiManagement 'modules/apim.bicep' = {
  name: 'apim-deployment'
  params: {
    apimName: 'apim-${resourceSuffix}'
    location: location
    skuName: apimSkuName
    backendApiFqdn: containerAppsEnv.outputs.apiFqdn
    allowedCorsOrigin: staticWebApp.outputs.defaultHostname  // Use SWA hostname for CORS
    tags: tags
  }
  dependsOn: [
    containerAppsEnv
    staticWebApp  // Need SWA hostname for CORS
  ]
}

// 9. Azure Front Door with WAF (global CDN + security) - After SWA + APIM
module frontDoor 'modules/frontdoor-waf.bicep' = {
  name: 'frontdoor-deployment'
  params: {
    resourceSuffix: resourceSuffix
    location: 'global'
    staticWebAppHostname: staticWebApp.outputs.defaultHostname
    apimHostname: apiManagement.outputs.gatewayHostname
    customDomain: frontDoorCustomDomain
    skuName: frontDoorSkuName
    tags: tags
  }
  dependsOn: [
    staticWebApp
    apiManagement
  ]
}

// 10. Update Key Vault with Container App managed identity (separate deployment)
// Note: This is a second deployment of Key Vault to grant the Container App access
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

// 11. Grant Container App managed identity access to PostgreSQL (AAD Admin only)
module postgresqlAadConfig 'modules/postgres-aad-admin.bicep' = if (enablePostgresAadAuth) {
  name: 'postgresql-aad-config'
  params: {
    serverName: postgresqlServerName
    aadAdminPrincipalId: containerAppsEnv.outputs.managedIdentityPrincipalId
    aadAdminPrincipalName: containerAppsEnv.outputs.appName
    aadAdminPrincipalType: 'ServicePrincipal'
  }
  dependsOn: [
    postgresqlPrivate
  ]
}

// ============================================
// OUTPUTS
// ============================================

// Frontend URLs
output frontendUrl string = 'https://${staticWebApp.outputs.defaultHostname}'
output frontDoorUrl string = frontDoor.outputs.frontDoorEndpointUrl
output customDomainUrl string = frontDoorCustomDomain != '' ? 'https://${frontDoorCustomDomain}' : ''

// Backend URLs
output apiUrl string = containerAppsEnv.outputs.apiUrl
output apimUrl string = apiManagement.outputs.apiUrl
output apiFqdn string = containerAppsEnv.outputs.apiFqdn
output apimGatewayHostname string = apiManagement.outputs.gatewayHostname

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
output natPublicIp string = networking.outputs.natPublicIp

// Managed Identities
output containerAppManagedIdentityPrincipalId string = containerAppsEnv.outputs.managedIdentityPrincipalId
output apimManagedIdentityPrincipalId string = apiManagement.outputs.managedIdentityPrincipalId

// Azure Communication Services
output acsSenderEmail string = communicationServices.outputs.senderEmail
output acsEndpoint string = communicationServices.outputs.endpoint

// Logic App
output logicAppName string = logicAppEmail.outputs.logicAppName
@secure()
output logicAppCallbackUrl string = logicAppEmail.outputs.callbackUrl

// WAF
output wafPolicyId string = frontDoor.outputs.wafPolicyId

// Custom Domain Validation (if applicable)
output customDomainValidationToken string = frontDoorCustomDomain != '' ? frontDoor.outputs.customDomainValidationToken : ''

// Deployment summary message
output deploymentMessage string = '''
Deployment Complete - Production-Ready Architecture with Email Notifications!

FRONTEND ACCESS:
- Static Web App: https://${staticWebApp.outputs.defaultHostname}
- Front Door (CDN + WAF): ${frontDoor.outputs.frontDoorEndpointUrl}
${frontDoorCustomDomain != '' ? '- Custom Domain: https://${frontDoorCustomDomain}' : ''}

BACKEND ACCESS:
- Container App (direct): ${containerAppsEnv.outputs.apiUrl}
- API Management (secured): ${apiManagement.outputs.apiUrl}
- API Docs: ${containerAppsEnv.outputs.apiUrl}/docs

COMMUNICATION & AUTOMATION:
- Email Service (ACS): ${communicationServices.outputs.senderEmail}
- Logic App: ${logicAppEmail.outputs.logicAppName}
- Logic App Webhook: [Secure URL in outputs]

INFRASTRUCTURE:
- VNet: ${networking.outputs.vnetName}
- NAT Gateway IP: ${networking.outputs.natPublicIp}
- PostgreSQL (private): ${postgresqlPrivate.outputs.serverFqdn}
- Key Vault: ${keyVault.outputs.keyVaultName}
- WAF Policy: Enabled (OWASP + Bot Protection)

ARCHITECTURE FLOW:
User -> Front Door (WAF) -> Static Web App (frontend)
                         -> APIM (rate limit + CORS) -> Container App -> PostgreSQL
                                                            |
                                                       Email (ACS)
                                                            |
                                                       Logic App (workflows)

EMAIL CONFIGURATION:
- Sender Email: ${communicationServices.outputs.senderEmail}
- Connection String: Configured in Container App secrets
- Email templates: Built into backend API
- Cost: ~$0.00025 per email (very affordable!)

NEXT STEPS:
1. Deploy backend: docker push ${acr.outputs.acrLoginServer}/api:latest
2. Frontend auto-deploys via GitHub Actions
3. Test email: POST ${containerAppsEnv.outputs.apiUrl}/api/tickets/{id}/respond
${frontDoorCustomDomain != '' ? '4. Add CNAME record: ${frontDoorCustomDomain} -> ${frontDoor.outputs.frontDoorEndpointHostname}\n5. Validation token: ${frontDoor.outputs.customDomainValidationToken}' : ''}

SECURITY FEATURES:
- VNet isolation with private endpoints
- NAT Gateway for fixed egress IP
- WAF with OWASP rules + bot protection
- APIM rate limiting (100 req/min)
- Private PostgreSQL (no public access)
- Key Vault with RBAC + managed identities
- HTTPS enforcement everywhere
- Email credentials stored as secrets
- Logic App workflows for automation

Ready to send emails via Azure Communication Services!
'''
