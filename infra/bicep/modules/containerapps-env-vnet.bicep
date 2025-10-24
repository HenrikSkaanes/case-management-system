// Container Apps Environment with VNet Injection
// Includes Container App with managed identity and IP restrictions

@description('Container App Environment name')
param environmentName string

@description('Container App name')
param appName string

@description('Location for resources')
param location string = resourceGroup().location

@description('Control plane subnet ID')
param subnetAcaControlId string

@description('Runtime subnet ID')
param subnetAcaRuntimeId string

@description('Log Analytics workspace ID')
param logAnalyticsWorkspaceId string

@description('Log Analytics workspace customer ID')
param logAnalyticsCustomerId string

@description('Container image to deploy')
param containerImage string

@description('Container registry server')
param containerRegistryServer string = ''

@description('Container registry username')
@secure()
param containerRegistryUsername string = ''

@description('Container registry password')
@secure()
param containerRegistryPassword string = ''

@description('Database connection string')
@secure()
param databaseConnectionString string

@description('Allowed CORS origin')
param allowedCorsOrigin string = ''

@description('APIM egress IP addresses (comma-separated) for IP restrictions')
param apimEgressIps string = ''

@description('Target port for container')
param targetPort int = 8000

@description('CPU allocation')
param cpu string = '0.5'

@description('Memory allocation')
param memory string = '1.0Gi'

@description('Min replicas')
param minReplicas int = 1

@description('Max replicas')
param maxReplicas int = 5

@description('Tags to apply to resources')
param tags object = {}

// Container App Environment with VNet injection
resource environment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: environmentName
  location: location
  tags: tags
  properties: {
    vnetConfiguration: {
      infrastructureSubnetId: subnetAcaControlId
      internal: false // TODO: Set to true when APIM is in internal mode with Private Link
    }
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsCustomerId
        sharedKey: listKeys(logAnalyticsWorkspaceId, '2023-09-01').primarySharedKey
      }
    }
    zoneRedundant: false // Enable for production
  }
}

// Build registry configuration if credentials provided
var registryConfig = !empty(containerRegistryServer) && !empty(containerRegistryUsername) ? [
  {
    server: containerRegistryServer
    username: containerRegistryUsername
    passwordSecretRef: 'registry-password'
  }
] : []

// Build secrets array
var secrets = concat(
  [
    {
      name: 'database-url'
      value: databaseConnectionString
    }
  ],
  !empty(containerRegistryPassword) ? [
    {
      name: 'registry-password'
      value: containerRegistryPassword
    }
  ] : []
)

// Build IP restrictions if APIM IPs provided
// TODO: Verify ipSecurityRestrictions property is supported in your API version
var ipRestrictions = !empty(apimEgressIps) ? [
  {
    name: 'AllowAPIM'
    ipAddressRange: apimEgressIps
    action: 'Allow'
  }
] : []

// Container App with managed identity
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: appName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      ingress: {
        external: true // Public ingress for POC; TODO: Set to false when APIM is internal
        targetPort: targetPort
        transport: 'http'
        allowInsecure: false
        // TODO: Uncomment when ipSecurityRestrictions is fully supported
        // ipSecurityRestrictions: ipRestrictions
      }
      registries: registryConfig
      secrets: secrets
    }
    template: {
      containers: [
        {
          name: 'api'
          image: containerImage
          resources: {
            cpu: json(cpu)
            memory: memory
          }
          env: [
            {
              name: 'DATABASE_URL'
              secretRef: 'database-url'
            }
            {
              name: 'ALLOWED_ORIGIN'
              value: allowedCorsOrigin
            }
            {
              name: 'PORT'
              value: string(targetPort)
            }
          ]
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
}

// Outputs
output environmentId string = environment.id
output environmentName string = environment.name
output appName string = containerApp.name
output apiFqdn string = containerApp.properties.configuration.ingress.fqdn
output apiUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output managedIdentityPrincipalId string = containerApp.identity.principalId
output apiOutboundIps array = environment.properties.staticIp != null ? [environment.properties.staticIp] : []
