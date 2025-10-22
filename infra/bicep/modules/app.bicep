// Container App
// The actual application running in a container

@description('Name of the Container App')
param appName string

@description('Location for the app')
param location string = resourceGroup().location

@description('Container App Environment ID')
param environmentId string

@description('Container Registry login server (e.g., myregistry.azurecr.io)')
param acrLoginServer string

@description('Container image name with tag (e.g., case-management:latest)')
param imageName string = 'case-management:latest'

@description('Use public placeholder image for initial deployment')
param usePublicImage bool = false

@description('Container Registry username (optional)')
@secure()
param acrUsername string = ''

@description('Container Registry password (optional)')
@secure()
param acrPassword string = ''

@description('CPU cores (0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0)')
param cpu string = '0.5'

@description('Memory in Gi (0.5, 1.0, 1.5, 2.0, 3.0, 3.5, 4.0)')
param memory string = '1.0Gi'

@description('Minimum number of replicas')
param minReplicas int = 1

@description('Maximum number of replicas')
param maxReplicas int = 3

@description('Tags to apply to resources')
param tags object = {}

@description('Database connection string (secure)')
@secure()
param databaseConnectionString string = ''

@description('Azure Communication Services connection string (secure)')
@secure()
param acsConnectionString string = ''

@description('ACS sender email address')
param acsSenderEmail string = ''

@description('Company name for email signatures')
param companyName string = 'Wrangler Tax Services'

// Determine whether to configure ACR credentials
var useRegistryCredentials = !usePublicImage && acrUsername != '' && acrPassword != ''

// Build secrets collection without using list* functions to avoid deployment errors
var combinedSecrets = concat(
  [
    {
      name: 'database-url'
      value: databaseConnectionString
    }
  ],
  empty(acsConnectionString) ? [] : [
    {
      name: 'acs-connection-string'
      value: acsConnectionString
    }
  ],
  useRegistryCredentials ? [
    {
      name: 'acr-password'
      value: acrPassword
    }
  ] : []
)

// Build environment variables referencing secrets when present
var environmentVariables = concat(
  [
    {
      name: 'DATABASE_URL'
      secretRef: 'database-url'
    }
    {
      name: 'COMPANY_NAME'
      value: companyName
    }
  ],
  empty(acsConnectionString) ? [] : [
    {
      name: 'ACS_CONNECTION_STRING'
      secretRef: 'acs-connection-string'
    }
  ],
  empty(acsSenderEmail) ? [] : [
    {
      name: 'ACS_SENDER_EMAIL'
      value: acsSenderEmail
    }
  ]
)

// Create Container App
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: appName
  location: location
  tags: tags
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      ingress: {
        external: true // Accessible from internet
        targetPort: 8000 // Port your app listens on
        transport: 'http'
        allowInsecure: false // Use HTTPS
      }
      registries: useRegistryCredentials ? [
        {
          server: acrLoginServer
          username: acrUsername
          passwordSecretRef: 'acr-password'
        }
      ] : []
      secrets: combinedSecrets
    }
    template: {
      containers: [
        {
          name: 'case-management'
          image: usePublicImage ? 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest' : '${acrLoginServer}/${imageName}'
          resources: {
            cpu: json(cpu)
            memory: memory
          }
          env: environmentVariables
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
                concurrentRequests: '10' // Scale up when >10 concurrent requests
              }
            }
          }
        ]
      }
    }
  }
}

// Outputs
output appUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output appName string = containerApp.name
output fqdn string = containerApp.properties.configuration.ingress.fqdn
