// Azure Communication Services Module
// Creates Email Service and Communication Service for sending emails

@description('Base name for Communication Services resources')
param baseName string

@description('Location for Communication Services (limited to specific regions)')
@allowed([
  'global'
  'europe'
  'unitedstates'
])
param location string = 'global'

@description('Data location for Communication Services (GDPR compliance)')
@allowed([
  'Europe'
  'UnitedStates'
  'Asia'
  'Australia'
])
param dataLocation string = 'Europe'

@description('Tags to apply to resources')
param tags object = {}

// ============================================
// EMAIL SERVICE
// ============================================

resource emailService 'Microsoft.Communication/emailServices@2023-03-31' = {
  name: 'email-${baseName}'
  location: location
  tags: tags
  properties: {
    dataLocation: dataLocation
  }
}

// ============================================
// EMAIL DOMAIN (Azure Managed)
// ============================================

resource emailDomain 'Microsoft.Communication/emailServices/domains@2023-03-31' = {
  parent: emailService
  name: 'AzureManagedDomain'
  location: location
  tags: tags
  properties: {
    domainManagement: 'AzureManaged'  // Microsoft manages DNS, SPF, DKIM
    userEngagementTracking: 'Disabled'  // Privacy-friendly
  }
}

// ============================================
// COMMUNICATION SERVICE
// ============================================

resource communicationService 'Microsoft.Communication/communicationServices@2023-03-31' = {
  name: 'acs-${baseName}'
  location: location
  tags: tags
  properties: {
    dataLocation: dataLocation
    linkedDomains: [
      emailDomain.id
    ]
  }
}

// ============================================
// OUTPUTS
// ============================================

@description('Email Service resource ID')
output emailServiceId string = emailService.id

@description('Email Service resource name')
output emailServiceName string = emailService.name

@description('Email Domain resource ID')
output emailDomainId string = emailDomain.id

@description('Email Domain resource name')
output emailDomainName string = emailDomain.name

@description('Communication Service resource ID')
output communicationServiceId string = communicationService.id

@description('Communication Service resource name')
output communicationServiceName string = communicationService.name

@description('Sender email address for sending emails')
output senderEmail string = 'DoNotReply@${emailDomain.properties.mailFromSenderDomain}'

@description('Communication Service connection string (sensitive)')
@secure()
output connectionString string = communicationService.listKeys().primaryConnectionString

@description('Communication Service endpoint')
output endpoint string = communicationService.properties.hostName
