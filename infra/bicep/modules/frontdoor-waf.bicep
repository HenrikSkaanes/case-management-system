@description('The suffix for naming resources.')
param resourceSuffix string

@description('The location for the Azure Front Door resources. Front Door is a global service but its resources need a location.')
param location string = 'global'

@description('The hostname of the Static Web App to use as the backend origin.')
param staticWebAppHostname string

@description('The hostname of the API Management to use as the backend origin.')
param apimHostname string

@description('Optional custom domain for Front Door. If not provided, will use the default azurefd.net domain.')
param customDomain string = ''

@description('The SKU name for Azure Front Door.')
@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
param skuName string = 'Standard_AzureFrontDoor'

@description('Tags to apply to all resources.')
param tags object = {}

// Note: WAF is only available with Premium tier
// Standard tier provides CDN, SSL, routing but no WAF

// ================================================================
// Azure Front Door Profile
// ================================================================

resource frontDoorProfile 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: 'afd-${resourceSuffix}'
  location: location
  sku: {
    name: skuName
  }
  tags: tags
  properties: {
    originResponseTimeoutSeconds: 60
  }
}

// ================================================================
// WAF Policy (Only for Premium tier)
// ================================================================

resource wafPolicy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2022-05-01' = if (skuName == 'Premium_AzureFrontDoor') {
  name: 'waf${replace(resourceSuffix, '-', '')}' // WAF name can't have dashes
  location: 'global'
  sku: {
    name: skuName
  }
  tags: tags
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: 'Prevention' // Use 'Detection' for POC if you want to see what would be blocked without blocking
      requestBodyCheck: 'Enabled'
      // TODO: For production, set customBlockResponseStatusCode: 403 and customBlockResponseBody: base64-encoded message
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '2.1'
          ruleSetAction: 'Block'
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '1.0'
          ruleSetAction: 'Block'
        }
      ]
    }
    // TODO: Add custom rules for specific IP allow/deny lists, geo-blocking, etc.
  }
}

// ================================================================
// Front Door Endpoint
// ================================================================

resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-05-01' = {
  parent: frontDoorProfile
  name: 'endpoint-${resourceSuffix}'
  location: location
  properties: {
    enabledState: 'Enabled'
  }
}

// ================================================================
// Origin Groups
// ================================================================

// Origin group for Static Web App (frontend)
resource originGroupSwa 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = {
  parent: frontDoorProfile
  name: 'og-swa'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 100
    }
    sessionAffinityState: 'Disabled'
  }
}

// Origin group for API Management (backend)
resource originGroupApim 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = {
  parent: frontDoorProfile
  name: 'og-apim'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    healthProbeSettings: {
      probePath: '/status-0123456789abcdef' // APIM built-in health endpoint
      probeRequestType: 'HEAD'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 100
    }
    sessionAffinityState: 'Disabled'
  }
}

// ================================================================
// Origins
// ================================================================

// Static Web App origin
resource originSwa 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  parent: originGroupSwa
  name: 'origin-swa'
  properties: {
    hostName: staticWebAppHostname
    httpPort: 80
    httpsPort: 443
    originHostHeader: staticWebAppHostname
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
    enforceCertificateNameCheck: true
  }
}

// API Management origin
resource originApim 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  parent: originGroupApim
  name: 'origin-apim'
  properties: {
    hostName: apimHostname
    httpPort: 80
    httpsPort: 443
    originHostHeader: apimHostname
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
    enforceCertificateNameCheck: true
  }
}

// ================================================================
// Routes
// ================================================================

// Route for frontend (all paths except /api/*)
resource routeSwa 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = {
  parent: endpoint
  name: 'route-swa'
  dependsOn: [
    originSwa // Ensure origin is created before route
  ]
  properties: {
    customDomains: customDomain != '' ? [
      {
        id: customDomainResource.id
      }
    ] : []
    originGroup: {
      id: originGroupSwa.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
    enabledState: 'Enabled'
    cacheConfiguration: {
      queryStringCachingBehavior: 'IgnoreQueryString'
      compressionSettings: {
        contentTypesToCompress: [
          'text/html'
          'text/css'
          'application/javascript'
          'application/json'
        ]
        isCompressionEnabled: true
      }
    }
  }
}

// Route for API (paths starting with /api/*)
resource routeApim 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = {
  parent: endpoint
  name: 'route-apim'
  dependsOn: [
    originApim // Ensure origin is created before route
  ]
  properties: {
    customDomains: customDomain != '' ? [
      {
        id: customDomainResource.id
      }
    ] : []
    originGroup: {
      id: originGroupApim.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/api/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
    enabledState: 'Enabled'
    // No caching for API calls
    cacheConfiguration: {
      queryStringCachingBehavior: 'UseQueryString'
    }
  }
}

// ================================================================
// Security Policy (links WAF to endpoint) - Only for Premium tier
// ================================================================

resource securityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2023-05-01' = if (skuName == 'Premium_AzureFrontDoor') {
  parent: frontDoorProfile
  name: 'security-policy'
  properties: {
    parameters: {
      type: 'WebApplicationFirewall'
      wafPolicy: {
        id: wafPolicy.id
      }
      associations: [
        {
          domains: [
            {
              id: endpoint.id
            }
          ]
          patternsToMatch: [
            '/*'
          ]
        }
      ]
    }
  }
}

// ================================================================
// Custom Domain (Optional)
// ================================================================

// TODO: Custom domain requires DNS validation
// You'll need to create a CNAME record pointing to the Front Door endpoint hostname
// and then add the custom domain to Front Door with a managed certificate
resource customDomainResource 'Microsoft.Cdn/profiles/customDomains@2023-05-01' = if (customDomain != '') {
  parent: frontDoorProfile
  name: replace(customDomain, '.', '-')
  properties: {
    hostName: customDomain
    tlsSettings: {
      certificateType: 'ManagedCertificate'
      minimumTlsVersion: 'TLS12'
    }
  }
}

// ================================================================
// Outputs
// ================================================================

output frontDoorId string = frontDoorProfile.id
output frontDoorName string = frontDoorProfile.name
output frontDoorEndpointHostname string = endpoint.properties.hostName
output frontDoorEndpointUrl string = 'https://${endpoint.properties.hostName}'
output wafPolicyId string = skuName == 'Premium_AzureFrontDoor' ? wafPolicy.id : 'N/A - Standard tier does not include WAF'
output customDomainValidationToken string = customDomain != '' ? customDomainResource.properties.validationProperties.validationToken : ''
