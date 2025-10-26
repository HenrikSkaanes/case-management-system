// API Management Module
// External API façade with CORS, rate limiting, and JWT validation (TODO)

@description('APIM instance name')
param apimName string

@description('Location for resources')
param location string = resourceGroup().location

@description('APIM SKU')
@allowed([
  'Consumption'
  'Developer'
  'Basic'
  'Standard'
  'Premium'
])
param skuName string = 'Consumption'

@description('Publisher email')
param publisherEmail string = 'admin@example.com'

@description('Publisher name')
param publisherName string = 'Case Management System'

@description('Backend Container App FQDN')
param backendApiFqdn string

@description('Allowed CORS origin (e.g., SWA hostname)')
param allowedCorsOrigin string

@description('Tags to apply to resources')
param tags object = {}

// API Management instance
resource apim 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
  name: apimName
  location: location
  tags: tags
  sku: {
    name: skuName
    capacity: skuName == 'Consumption' ? 0 : 1  // Consumption tier uses capacity 0
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    // TODO: Configure VNet integration for internal mode
    // virtualNetworkType: 'Internal'
    // virtualNetworkConfiguration: {
    //   subnetResourceId: subnetApimId
    // }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// API for Case Management backend
resource api 'Microsoft.ApiManagement/service/apis@2023-03-01-preview' = {
  parent: apim
  name: 'case-api'
  properties: {
    displayName: 'Case Management API'
    description: 'API for case management operations'
    path: 'api'
    protocols: [
      'https'
    ]
    serviceUrl: 'https://${backendApiFqdn}'
    subscriptionRequired: false // TODO: Enable when implementing API keys
    type: 'http'
  }
}

// Wildcard operation to proxy all requests to backend
resource apiOperationAll 'Microsoft.ApiManagement/service/apis/operations@2023-03-01-preview' = {
  parent: api
  name: 'all-operations'
  properties: {
    displayName: 'All Operations'
    method: '*'
    urlTemplate: '/*'
    description: 'Proxy all requests to Container App backend'
  }
}

// CORS + JWT validation policy
resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-03-01-preview' = {
  parent: api
  name: 'policy'
  properties: {
    value: '''
<policies>
  <inbound>
    <base />
    <!-- Set allowed CORS origin as variable -->
    <set-variable name="allowedCorsOrigin" value="${allowedCorsOrigin}" />
    
    <!-- CORS policy - strict, only allows SWA origin -->
    <cors allow-credentials="false">
      <allowed-origins>
        <origin>@((string)context.Variables["allowedCorsOrigin"])</origin>
      </allowed-origins>
      <allowed-methods>
        <method>GET</method>
        <method>POST</method>
        <method>PUT</method>
        <method>DELETE</method>
        <method>PATCH</method>
        <method>OPTIONS</method>
      </allowed-methods>
      <allowed-headers>
        <header>authorization</header>
        <header>content-type</header>
        <header>x-requested-with</header>
        <header>accept</header>
      </allowed-headers>
      <expose-headers>
        <header>content-length</header>
        <header>content-type</header>
      </expose-headers>
    </cors>
    
    <!-- Rate limiting: 100 calls per minute (simple rate-limit works in Consumption SKU) -->
    <rate-limit calls="100" renewal-period="60" />
    
    <!-- TODO: Add JWT validation when Entra ID auth is implemented -->
    <!--
    <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized">
      <openid-config url="https://login.microsoftonline.com/{tenant-id}/v2.0/.well-known/openid-configuration" />
      <audiences>
        <audience>api://case-management-api</audience>
      </audiences>
      <required-claims>
        <claim name="scp" match="all">
          <value>access_as_user</value>
        </claim>
      </required-claims>
    </validate-jwt>
    -->
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
'''
    format: 'xml'
  }
}

// Product for organizing APIs (optional, for future API key management)
resource product 'Microsoft.ApiManagement/service/products@2023-03-01-preview' = {
  parent: apim
  name: 'case-management'
  properties: {
    displayName: 'Case Management'
    description: 'Access to Case Management APIs'
    subscriptionRequired: false // No API keys required for now
    state: 'published'
  }
}

// Link API to product
resource productApi 'Microsoft.ApiManagement/service/products/apis@2023-03-01-preview' = {
  parent: product
  name: api.name
}

// Outputs
output apimId string = apim.id
output apimName string = apim.name
output gatewayHostname string = replace(apim.properties.gatewayUrl, 'https://', '')
output apiUrl string = '${apim.properties.gatewayUrl}/api'
output publicIpAddresses array = apim.properties.publicIPAddresses ?? []
output managedIdentityPrincipalId string = apim.identity.principalId
