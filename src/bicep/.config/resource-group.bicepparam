// Abbreviation Mappings:
// Organization = tcsnlps
// workload = LandingZoneConfigAuditor - lzca
// application = Dashboards = dash
// env = production - p | development - d | test - t
// svc suffixes: rg (Resource Group), kv (Key Vault), law (Log Analytics Workspace), sec (Secret)
// Full naming pattern:
// <organization>-<workload>-<env>-<application>-<svc><NNN>-<sub-svc><NN>

using '../modules/resource-group.bicep'

param name = readEnvironmentVariable('RESOURCE_GROUP_NAME')
param location = readEnvironmentVariable('RESOURCE_GROUP_LOCATION')
