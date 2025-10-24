// Key Vault Module
// Secure secrets storage with RBAC, soft delete, and purge protection

@description('Key Vault name')
param keyVaultName string

@description('Location for resources')
param location string = resourceGroup().location

@description('Object ID of the principal (managed identity) that needs access')
param principalId string = ''

@description('Enable RBAC authorization (recommended)')
param enableRbacAuthorization bool = true

@description('Tags to apply to resources')
param tags object = {}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: enableRbacAuthorization
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    publicNetworkAccess: 'Enabled' // TODO: Change to 'Disabled' when adding Private Link
    networkAcls: {
      defaultAction: 'Allow' // TODO: Change to 'Deny' + allowlist when private
      bypass: 'AzureServices'
    }
  }
}

// Grant Key Vault Secrets User role to the Container App managed identity
// Role: Key Vault Secrets User (4633458b-17de-408a-b874-0445c86b69e6)
resource keyVaultSecretUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  name: guid(keyVault.id, principalId, '4633458b-17de-408a-b874-0445c86b69e6')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
