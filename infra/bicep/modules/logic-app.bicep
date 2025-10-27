// Logic App Module
// Creates a Logic App (Consumption) for workflow automation

@description('Name of the Logic App')
param logicAppName string

@description('Location for the Logic App')
param location string = resourceGroup().location

@description('Logic App definition (workflow)')
param definition object

@description('Parameters for the Logic App workflow')
param parameters object = {}

@description('Integration Account ID (optional)')
param integrationAccountId string = ''

@description('State of the Logic App (Enabled or Disabled)')
@allowed([
  'Enabled'
  'Disabled'
])
param state string = 'Enabled'

@description('Tags to apply to resources')
param tags object = {}

// ============================================
// LOGIC APP (CONSUMPTION)
// ============================================

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: tags
  properties: {
    state: state
    definition: definition
    parameters: parameters
    integrationAccount: !empty(integrationAccountId) ? {
      id: integrationAccountId
    } : null
  }
}

// ============================================
// OUTPUTS
// ============================================

@description('Logic App resource ID')
output logicAppId string = logicApp.id

@description('Logic App resource name')
output logicAppName string = logicApp.name

@description('Logic App callback URL (if HTTP trigger exists)')
@secure()
output callbackUrl string = listCallbackUrl('${logicApp.id}/triggers/manual', '2019-05-01').value
