// Abbreviation Mappings:
// workload = LandingZoneConfigAuditor - lzca
// application = Dashboards = dash
// env = production - p | development - d | test - t
// svc suffixes: rg (Resource Group), kv (Key Vault), law (Log Analytics Workspace), sec (Secret)
// Full naming pattern:
// <workload>-<env>-<application>-<svc><unique-identifier>-<sub-svc><unique-identifier>

using '../main.bicep'

param logAnalyticsWorkspace_Name = readEnvironmentVariable('LOG_ANALYTICS_WORKSPACE_NAME')
param keyVault_Name = readEnvironmentVariable('KEY_VAULT_NAME')

param secrets = [
  { name: 'azureDevOpsOrganizationId', value: readEnvironmentVariable('AZDO_ORG_ID') }
  { name: 'azureDevOpsArtifactOrganizationName', value: readEnvironmentVariable('AZDO_ARTIFACT_ORG_NAME') }
  { name: 'azureDevOpsArtifactProjectName', value: readEnvironmentVariable('AZDO_ARTIFACT_PROJECT_NAME') }
  { name: 'azureDevOpsArtifactProjectNameFeedName', value: readEnvironmentVariable('AZDO_ARTIFACT_PROJECT_FEED_NAME') }
  { name: 'azureDevOpsArtifactPatToken', value: readEnvironmentVariable('AZDO_ARTIFACT_PAT_TOKEN') }
  { name: 'azureDevOpsArtifactPatUser', value: readEnvironmentVariable('AZDO_ARTIFACT_PAT_USER') }
  { name: 'targetAzureDevOpsOrganizationID', value: readEnvironmentVariable('AZDO_TARGET_ORG_ID') }
  { name: 'targetAzureDevOpsOrganizationName', value: readEnvironmentVariable('AZDO_TARGET_ORG_NAME') }
  { name: 'psrule-rules-azuredevops-apikey', value: readEnvironmentVariable('PSRULE_AZDO_APIKEY') }
  { name: 'targetAzureDevOpsSpnClientId', value: readEnvironmentVariable('AZDO_SPN_CLIENT_ID') }
  { name: 'targetAzureDevOpsSpnClientSecret', value: readEnvironmentVariable('AZDO_SPN_CLIENT_SECRET') }
  { name: 'targetAzureDevOpsSpnTenantId', value: readEnvironmentVariable('AZDO_SPN_TENANT_ID') }
]
