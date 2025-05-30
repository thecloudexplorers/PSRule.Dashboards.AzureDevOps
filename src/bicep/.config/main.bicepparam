// Abbreviation Mappings:
// workload = LandingZoneConfigAuditor - lzca
// application = Dashboards = dash
// env = production - p | development - d | test - t
// svc suffixes: rg (Resource Group), kv (Key Vault), law (Log Analytics Workspace), sec (Secret)
// Full naming pattern:
// <workload>-<env>-<application>-<svc><NNN>-<sub-svc><NN>

using '../main.bicep'

param logAnalyticsWorkspace_Name = 'lzca-p-dash-law001'
param keyVault_Name = 'lzca-p-dash-kv001'

param secrets = [
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
