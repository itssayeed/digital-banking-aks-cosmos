param baseName string
param location string
param tags object = {}

var uniqueSuffix = uniqueString(resourceGroup().id)
var storageBase = toLower('${baseName}st')
var storageName = '${take(storageBase, 24 - length(uniqueSuffix))}${uniqueSuffix}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    allowSharedKeyAccess: false
    publicNetworkAccess: 'Enabled'
  }
}

output storageAccountName string = storageAccount.name
output storagePrimaryBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob