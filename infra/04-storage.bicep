param baseName string
param location string

// Storage account name must be globally unique, only lowercase letters & numbers, 3-24 chars
var storageName = toLower('${baseName}st${uniqueString(resourceGroup().id)}')

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_LRS' // Lowest cost
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'        // But still cheap
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

output storageAccountName string = storageAccount.name
