targetScope = 'resourceGroup'

@description('Log Analytics Workspace Name')
param logAnalyticsWorkspace_Name string

@description('Key Vault Name')
param keyVault_Name string

@description('Location for all resources')
param location string = resourceGroup().location

@description('List of Key Vault secrets to create.\nEach object must have a `name` (string) and a `value` (string).\nValues may be empty strings.')
param secrets array = [
  { name: 'azureDevOpsOrganizationId', value: '' }
  { name: 'azureDevOpsOrganizationName', value: '' }
  { name: 'azureDevOpsArtifactOrganizationName', value: '' }
  { name: 'azureDevOpsArtifactProjectName', value: '' }
  { name: 'azureDevOpsArtifactProjectNameFeedName', value: '' }
  { name: 'azureDevOpsArtifactPatToken', value: '' }
  { name: 'azureDevOpsArtifactPatUser', value: '' }
  { name: 'targetAzureDevOpsOrganizationID', value: '' }
  { name: 'targetAzureDevOpsOrganizationName', value: '' }
  { name: 'psruleRulesAzureDevopsApikey', value: '' }
  { name: 'targetAzureDevOpsSpnClientId', value: '' }
  { name: 'targetAzureDevOpsSpnClientSecret', value: '' }
  { name: 'targetAzureDevOpsSpnTenantId', value: '' }
]

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: logAnalyticsWorkspace_Name
  location: location
  properties: {
    sku: {
      name: 'pergb2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: false
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVault_Name
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enableRbacAuthorization: true
  }
}

// Create each secret dynamically from the `secrets` array
resource secretResources 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = [
  for secret in secrets: {
    parent: keyVault
    name: secret.name
    properties: {
      value: secret.value
    }
  }
]

resource secretWorkspaceId 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'logAnalyticsWorkspaceId'
  properties: {
    value: logAnalyticsWorkspace.properties.customerId
  }
}

resource secretWorkspaceSharedKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'logAnalyticsSharedKey'
  properties: {
    value: logAnalyticsWorkspace.listKeys().primarySharedKey
  }
}

module workbookAzDoMain 'modules/azdo-main.bicep' = {
  name: 'workbookAzDoMain'
  params: {
    workbook_AzureDevOpsMain_Name: guid('wb-azdo-main', resourceGroup().id)
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
    location: location
    AzDoResourceStateId: workbookAzDoResourceState.outputs.id
    AzDoRuleSummaryId: workbookAzDoSummaryByRule.outputs.id
  }
}

module workbookAzDoResourceByRule 'modules/azdo-resources-by-rule.bicep' = {
  name: 'workbookAzDoResourceByRule'
  params: {
    workbook_AzureDevOpsResourceByRule_Name: guid('wb-azdo-resources-byrule', resourceGroup().id)
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
    location: location
  }
}

module workbookAzDoRuleHitsByResource 'modules/azdo-rule-hits-by-resource.bicep' = {
  name: 'workbookAzDoRuleHitsByResource'
  params: {
    workbook_AzureDevOpsRuleHitsByResource_Name: guid('wb-azdo-rulehits-byresource', resourceGroup().id)
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
    location: location
  }
}

module workbookAzDoSummaryByRule 'modules/azdo-summary-by-rule.bicep' = {
  name: 'workbookAzDoSummaryByRule'
  params: {
    workbook_AzureDevOpsSummaryByRule_Name: guid('wb-azdo-summary-byrule', resourceGroup().id)
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
    location: location
    AzDoResourcesByRuleId: workbookAzDoResourceByRule.outputs.id
  }
}

module workbookAzDoResourceState 'modules/azdo-resource-state.bicep' = {
  name: 'workbookAzDoResourceState'
  params: {
    workbook_AzureDevOpsResourceState_Name: guid('wb-azdo-resource-state', resourceGroup().id)
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
    location: location
    AzDoRuleHitsByResourceId: workbookAzDoRuleHitsByResource.outputs.id
  }
}

resource workspaces_AzureDevOpsAuditing 'Microsoft.OperationalInsights/workspaces/tables@2021-12-01-preview' = {
  parent: logAnalyticsWorkspace
  name: 'AzureDevOpsAuditing'
  properties: {
    totalRetentionInDays: 30
    plan: 'Analytics'
    schema: {
      name: 'AzureDevOpsAuditing'
    }
    retentionInDays: 30
  }
}
