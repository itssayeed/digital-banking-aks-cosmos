param baseName string
param location string

// Cosmos account name must be all lowercase, only letters and numbers, length <= 44
var cosmosName = toLower('${baseName}cosmos${uniqueString(resourceGroup().id)}')

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: cosmosName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    enableFreeTier: true
    disableKeyBasedMetadataWriteAccess: false
  }
}

output cosmosDbName string = cosmos.name
