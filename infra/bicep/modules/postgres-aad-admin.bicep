// PostgreSQL Azure AD Administrator
// Adds AAD admin to existing PostgreSQL Flexible Server

@description('PostgreSQL server name')
param serverName string

@description('Azure AD admin principal ID (managed identity)')
param aadAdminPrincipalId string

@description('Azure AD admin principal name')
param aadAdminPrincipalName string

@description('Azure AD admin principal type')
@allowed(['User', 'Group', 'ServicePrincipal'])
param aadAdminPrincipalType string = 'ServicePrincipal'

// Reference to existing PostgreSQL server
resource postgresqlServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-03-01-preview' existing = {
  name: serverName
}

// Azure AD Administrator for PostgreSQL
resource postgresqlAadAdmin 'Microsoft.DBforPostgreSQL/flexibleServers/administrators@2023-03-01-preview' = {
  parent: postgresqlServer
  name: aadAdminPrincipalId
  properties: {
    principalType: aadAdminPrincipalType
    principalName: aadAdminPrincipalName
    tenantId: subscription().tenantId
  }
}

// Outputs
output aadAdminConfigured bool = true
output principalId string = aadAdminPrincipalId
