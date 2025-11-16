param baseName string
param location string

var cosmosName = toLower('${baseName}cosmos${uniqueString(resourceGroup().id)}')

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: cosmosName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    capabilities: [
      { name: 'EnableServerless' }
    ]
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
    enableFreeTier: true
  }
}

// Database
resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' = {
  name: '${cosmos.name}/dbanking'
  properties: {
    resource: { id: 'dbanking' }
  }
}

// Container
resource cosmosContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  name: '${cosmosDb.name}/accounts'
  properties: {
    resource: {
      id: 'accounts'
      partitionKey: {
        paths: ['/id']
        kind: 'Hash'
      }
    }
  }
}

output cosmosAccountName string = cosmos.name
output cosmosDatabaseName string = cosmosDb.name
output cosmosContainerName string = cosmosContainer.name
