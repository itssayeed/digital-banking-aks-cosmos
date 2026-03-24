param baseName string
param location string
param tags object = {}

var uniqueSuffix = uniqueString(resourceGroup().id)
var base = toLower('${baseName}cosmos')
var cosmosAccountName = '${take(base, 44 - length(uniqueSuffix))}${uniqueSuffix}'

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' = {
  name: cosmosAccountName
  location: location
  tags: tags
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    enableFreeTier: true
    disableLocalAuth: true
    publicNetworkAccess: 'Enabled'

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

resource cosmosDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-11-15' = {
  parent: cosmosAccount
  name: 'dbanking'
  properties: {
    resource: {
      id: 'dbanking'
    }
  }
}

resource cosmosContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-11-15' = {
  parent: cosmosDatabase
  name: 'accounts'
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

output cosmosAccountName string = cosmosAccount.name
output cosmosEndpoint string = cosmosAccount.properties.documentEndpoint
output cosmosDatabaseName string = 'dbanking'
output cosmosContainerName string = 'accounts'