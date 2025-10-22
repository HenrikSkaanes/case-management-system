// Azure Communication Services - Email Communication
// Provides email capabilities for sending customer responses

targetScope = 'resourceGroup'

// ============================================
// PARAMETERS
// ============================================

@description('Name of the Communication Services resource')
param communicationServicesName string

@description('Location for Communication Services')
param location string = 'global'  // ACS is a global service

@description('Name of the Email Communication Service')
param emailServiceName string

@description('Location for Email Service')
param emailServiceLocation string

@description('Name of the domain (use this for the sender email)')
param domainName string = 'AzureManagedDomain'  // Free managed domain

@description('Tags for resources')
param tags object = {}

// ============================================
// RESOURCES
// ============================================

// Email Communication Service (required for email)
resource emailService 'Microsoft.Communication/emailServices@2023-04-01' = {
  name: emailServiceName
  location: emailServiceLocation
  tags: tags
  properties: {
    dataLocation: emailServiceLocation
  }
}

// Azure Managed Domain (free subdomain under azurecomm.net)
resource emailDomain 'Microsoft.Communication/emailServices/domains@2023-04-01' = {
  parent: emailService
  name: domainName
  location: emailServiceLocation
  tags: tags
  properties: {
    domainManagement: 'AzureManaged'  // Microsoft manages DNS
    userEngagementTracking: 'Disabled'  // Privacy-friendly
  }
}

// Communication Services resource (connects to email service)
resource communicationService 'Microsoft.Communication/communicationServices@2023-04-01' = {
  name: communicationServicesName
  location: location
  tags: tags
  properties: {
    dataLocation: 'Norway'  // Store data in Norway for GDPR
    linkedDomains: [
      emailDomain.id
    ]
  }
}

// ============================================
// OUTPUTS
// ============================================

output communicationServiceId string = communicationService.id
output communicationServiceName string = communicationService.name
output emailServiceId string = emailService.id
output emailDomainId string = emailDomain.id

// From address to use in emails
// The Azure Managed Domain creates a subdomain like: AzureManagedDomain@xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.azurecomm.net
// We output a placeholder that will be configured after deployment
output senderEmail string = 'DoNotReply@azuremanageddomain.azurecomm.net'  // Placeholder - actual value available in Azure Portal after deployment

