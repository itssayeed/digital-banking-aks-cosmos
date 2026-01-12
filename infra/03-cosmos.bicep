param baseName string
param location string

// ------------------------------------------------------------------
// Cosmos account name
// - Lowercase (Cosmos requirement)
// - Unique per resource group
// ------------------------------------------------------------------
var cosmosAccountName = toLower('${baseName}cosmos${uniqueString(resourceGroup().id)}')

// ------------------------------------------------------------------
// Cosmos DB Account (SQL API, Serverless)
// ------------------------------------------------------------------
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: cosmosAccountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    enableFreeTier: true

    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]

    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]

    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
  }
}

// ------------------------------------------------------------------
// SQL Database
// ------------------------------------------------------------------
resource cosmosDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' = {
  name: '${cosmosAccount.name}/dbanking'
  properties: {
    resource: {
      id: 'dbanking'
    }
  }
}

// ------------------------------------------------------------------
// SQL Container
// ------------------------------------------------------------------
resource cosmosContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  name: '${cosmosDatabase.name}/accounts'
  properties: {
    resource: {
      id: 'accounts'
      partitionKey: {
        paths: [
          '/id'
        ]
        kind: 'Hash'
      }
    }
  }
}

// ------------------------------------------------------------------
// Outputs (WHAT YOUR APP & PIPELINE SHOULD CONSUME)
// ------------------------------------------------------------------
output cosmosAccountName string = cosmosAccount.name
output cosmosEndpoint string = cosmosAccount.properties.documentEndpoint

// Logical names (what apps usually want)
output cosmosDatabaseName string = 'dbanking'
output cosmosContainerName string = 'accounts'
