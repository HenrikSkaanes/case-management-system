// PostgreSQL Flexible Server with Private Access
// Deployed in delegated subnet with Private DNS integration

@description('PostgreSQL server name')
param serverName string

@description('Location for resources')
param location string = resourceGroup().location

@description('PostgreSQL version')
param postgresqlVersion string = '16'

@description('Administrator username')
param adminUsername string

@description('Administrator password')
@secure()
param adminPassword string

@description('Enable Azure AD authentication')
param enableAadAuth bool = true

@description('Azure AD admin principal ID (user or service principal)')
param aadAdminPrincipalId string = ''

@description('Azure AD admin principal name')
param aadAdminPrincipalName string = ''

@description('Azure AD admin principal type (User, Group, ServicePrincipal)')
param aadAdminPrincipalType string = 'ServicePrincipal'

@description('Database name')
param databaseName string

@description('SKU tier (Burstable, GeneralPurpose, MemoryOptimized)')
param skuTier string = 'Burstable'

@description('SKU name (Standard_B1ms, Standard_D2s_v3, etc.)')
param skuName string = 'Standard_B1ms'

@description('Storage size in GB')
param storageSizeGB int = 32

@description('Subnet ID for PostgreSQL delegation')
param subnetId string

@description('VNet ID for Private DNS zone link')
param vnetId string

@description('Resource group name for DNS zone (if different from deployment RG)')
param dnsZoneResourceGroupName string = ''

@description('Tags to apply to resources')
param tags object = {}

// Use provided RG or fallback to current deployment RG
var dnsResourceGroup = empty(dnsZoneResourceGroupName) ? resourceGroup().name : dnsZoneResourceGroupName

// Private DNS Zone for PostgreSQL
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.postgres.database.azure.com'
  location: 'global'
  tags: tags
}

// Link Private DNS Zone to VNet
resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${serverName}-vnet-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// PostgreSQL Flexible Server
resource postgresqlServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-03-01-preview' = {
  name: serverName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    version: postgresqlVersion
    administratorLogin: adminUsername
    administratorLoginPassword: adminPassword
    storage: {
      storageSizeGB: storageSizeGB
      autoGrow: 'Enabled'
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled' // Enable for production
    }
    network: {
      delegatedSubnetResourceId: subnetId
      privateDnsZoneArmResourceId: privateDnsZone.id
      // publicNetworkAccess is automatically set to 'Disabled' when using VNet delegation
    }
    // Enable Azure AD authentication
    authConfig: {
      activeDirectoryAuth: enableAadAuth ? 'Enabled' : 'Disabled'
      passwordAuth: 'Enabled' // Keep enabled for initial setup, can disable later
      tenantId: subscription().tenantId
    }
  }
  dependsOn: [
    privateDnsZoneLink
  ]
}

// Azure AD Administrator for PostgreSQL (if enabled)
resource postgresqlAadAdmin 'Microsoft.DBforPostgreSQL/flexibleServers/administrators@2023-03-01-preview' = if (enableAadAuth && !empty(aadAdminPrincipalId)) {
  parent: postgresqlServer
  name: aadAdminPrincipalId
  properties: {
    principalType: aadAdminPrincipalType
    principalName: aadAdminPrincipalName
    tenantId: subscription().tenantId
  }
}

// Database
resource database 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-03-01-preview' = {
  parent: postgresqlServer
  name: databaseName
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

// Firewall rule to allow Azure services (for initial setup/migrations)
resource firewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-03-01-preview' = {
  parent: postgresqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Outputs
output serverName string = postgresqlServer.name
output serverFqdn string = postgresqlServer.properties.fullyQualifiedDomainName
output databaseName string = database.name
output privateDnsZoneName string = privateDnsZone.name
output aadAuthEnabled bool = enableAadAuth
