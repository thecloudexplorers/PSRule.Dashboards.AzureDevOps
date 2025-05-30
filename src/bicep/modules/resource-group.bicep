targetScope = 'subscription'

@description('Required. The name of the Resource Group.')
param name string

@description('Optional. Location of the Resource Group. It uses the deployment\'s location when not provided.')
param location string = deployment().location

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  location: location
  name: name
  // tags: tags
  // managedBy: managedBy // removed due to immutable string, only used for managed resource groups
  properties: {}
}
