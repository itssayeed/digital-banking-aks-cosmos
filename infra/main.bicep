// infra/main.bicep
@description('Base name used to create resource names (lowercase, alphanumeric).')
param baseName string

@description('Azure region to deploy into (e.g. southindia)')
param location string = resourceGroup().location

@description('AKS node sku')
param agentVmSize string = 'Standard_D2s_v3'

@description('AKS node count')
param agentCount int = 2

@description('ACR sku')
param acrSku string = 'Standard'

@description('Cosmos DB throughput (RU/s). Set to 400 for Minimal')
param cosmosThroughput int = 400

@description('Tags applied to all resources')
param tags object = {
  project: 'digital-banking-aks-cosmos'
}

var normalizedBase = toLower(replace(baseName, ' ', ''))

// Generate globally-unique suffixes where required
var uniqueSuffix = uniqueString(resourceGroup().id, normalizedBase)
var acrName = toLower('${normalizedBase}acr${uniqueSuffix}')
var cosmosName = toLower('${normalizedBase}cosmos${uniqueSuffix}')
var aksName = toLower('${normalizedBase}-aks')

// Log Analytics Workspace
resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: '${normalizedBase}-law'
  location: location
  tags: tags
  properties: {}
  sku: {
    name: 'PerGB2018'
  }
}

// ACR
resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: false
  }
  tags: tags
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: '${normalizedBase}-kv'
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
    enableSoftDelete: true
  }
}

// Cosmos DB (Core / SQL API)
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2021-04-15' = {
  name: cosmosName
  location: location
  tags: tags
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    enableMultipleWriteLocations: false
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
  }
}

// Cosmos DB SQL Database and Container (serverless or provisioned RU)
resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-04-15' = {
  parent: cosmosAccount
  name: 'bankingdb'
  properties: {
    resource: {
      id: 'bankingdb'
    }
    options: {
      throughput: cosmosThroughput
    }
  }
}

// AKS cluster
resource aks 'Microsoft.ContainerService/managedClusters@2023-02-01' = {
  name: aksName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: '${normalizedBase}-aks'
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: agentCount
        vmSize: agentVmSize
        osType: 'Linux'
        mode: 'System'
      }
    ]
    linuxProfile: {
      adminUsername: 'azureuser'
      ssh: {
        publicKeys: [
          {
            keyData: 'ssh-rsa AAAAB3NzaC1...GeneratedByYouOrReplace'
          }
        ]
      }
    }
    servicePrincipalProfile: null
    addonProfiles: {
      kubeDashboard: {
        enabled: false
      }
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logWorkspace.id
        }
      }
    }
    enableRBAC: true
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
    }
  }
  dependsOn: [
    logWorkspace
  ]
}

// Grant AKS access to pull images from ACR -> Role assignment
resource acrPullRole 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = if (true) {
  name: guid(aks.id, acr.id, 'acrpull')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull role
    principalId: aks.identity.principalId
    principalType: 'ServicePrincipal'
    scope: acr.id
  }
  dependsOn: [
    aks
    acr
  ]
}

// Store Cosmos DB connection string as a Key Vault secret (placeholder)
resource vaultSecretPlaceholder 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'CosmosDbConnectionString'
  properties: {
    value: 'REPLACE_WITH_DEPLOY_TIME_VALUE'
  }
  dependsOn: [
    keyVault
    cosmosAccount
  ]
}

output aksName string = aks.name
output acrLoginServer string = acr.properties.loginServer
output keyVaultUri string = keyVault.properties.vaultUri
output logAnalyticsWorkspaceId string = logWorkspace.id
output cosmosEndpoint string = cosmosAccount.properties.documentEndpoint
