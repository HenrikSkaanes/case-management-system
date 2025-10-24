// Networking Module
// VNet with subnets for Container Apps and PostgreSQL, plus NAT Gateway for fixed egress

@description('VNet name')
param vnetName string

@description('Location for resources')
param location string = resourceGroup().location

@description('VNet address prefix')
param vnetAddressPrefix string = '10.10.0.0/16'

@description('Container Apps control plane subnet prefix')
param subnetAcaControlPrefix string = '10.10.1.0/24'

@description('Container Apps runtime subnet prefix')
param subnetAcaRuntimePrefix string = '10.10.2.0/24'

@description('PostgreSQL delegated subnet prefix')
param subnetPostgresPrefix string = '10.10.3.0/24'

@description('Tags to apply to resources')
param tags object = {}

// Public IP for NAT Gateway (for fixed egress IP)
resource natPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${vnetName}-nat-pip'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// NAT Gateway for fixed egress from Container Apps
resource natGateway 'Microsoft.Network/natGateways@2023-05-01' = {
  name: '${vnetName}-nat'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIpAddresses: [
      {
        id: natPublicIp.id
      }
    ]
    idleTimeoutInMinutes: 10
  }
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'aca-control'
        properties: {
          addressPrefix: subnetAcaControlPrefix
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'aca-runtime'
        properties: {
          addressPrefix: subnetAcaRuntimePrefix
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          natGateway: {
            id: natGateway.id
          }
        }
      }
      {
        name: 'postgres-delegated'
        properties: {
          addressPrefix: subnetPostgresPrefix
          delegations: [
            {
              name: 'PostgreSQLFlexibleServerDelegation'
              properties: {
                serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

// Outputs
output vnetId string = vnet.id
output vnetName string = vnet.name
output subnetAcaControlId string = '${vnet.id}/subnets/aca-control'
output subnetAcaRuntimeId string = '${vnet.id}/subnets/aca-runtime'
output subnetPostgresId string = '${vnet.id}/subnets/postgres-delegated'
output natPublicIp string = natPublicIp.properties.ipAddress
output natGatewayId string = natGateway.id
