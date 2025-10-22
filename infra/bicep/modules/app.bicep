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

@description('Container Registry name')
param acrName string

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

// Get existing Container Registry to read credentials
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

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
      registries: [
        {
          server: acrLoginServer
          username: containerRegistry.listCredentials().username
          passwordSecretRef: 'acr-password'
        }
      ]
      secrets: [
        {
          name: 'acr-password'
          value: containerRegistry.listCredentials().passwords[0].value
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'case-management'
          image: '${acrLoginServer}/${imageName}'
          resources: {
            cpu: json(cpu)
            memory: memory
          }
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
