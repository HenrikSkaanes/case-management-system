// Azure Database for PostgreSQL Flexible Server
// Managed PostgreSQL database service

@description('PostgreSQL server name')
param serverName string

@description('Location for the database')
param location string = resourceGroup().location

@description('Administrator username')
@secure()
param adminUsername string = 'caseadmin'

@description('Administrator password')
@secure()
param adminPassword string

@description('Database name')
param databaseName string = 'casemanagement'

@description('PostgreSQL version')
@allowed([
  '12'
  '13'
  '14'
  '15'
  '16'
])
param postgresqlVersion string = '16'

@description('SKU tier (Burstable, GeneralPurpose, MemoryOptimized)')
@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
param skuTier string = 'Burstable'

@description('SKU name (Standard_B1ms, Standard_B2s, Standard_D2s_v3, etc.)')
param skuName string = 'Standard_B1ms' // 1 vCore, 2 GB RAM - cheapest option

@description('Storage size in GB')
param storageSizeGB int = 32

@description('Tags to apply to resources')
param tags object = {}

// Create PostgreSQL Flexible Server
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
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled' // Enable for production
    }
  }
}

// Configure firewall to allow Azure services
resource firewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-03-01-preview' = {
  parent: postgresqlServer
  name: 'AllowAllAzureServicesAndResourcesWithinAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Create database
resource database 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-03-01-preview' = {
  parent: postgresqlServer
  name: databaseName
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

// Outputs
output serverFqdn string = postgresqlServer.properties.fullyQualifiedDomainName
output databaseName string = database.name
output connectionString string = 'postgresql://${adminUsername}@${serverName}:PASSWORD_HERE@${postgresqlServer.properties.fullyQualifiedDomainName}:5432/${databaseName}?sslmode=require'
