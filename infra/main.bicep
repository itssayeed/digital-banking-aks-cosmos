param baseName string = 'dbanking'
param location string = 'southindia'

@description('SSH public key for AKS nodes')
param sshPublicKey string

param adminUsername string = 'azureuser'

param tags object = {
  env: 'dev'
  project: 'digital-banking'
}

// 🔥 Centralized suffix (dynamic per deployment)
var uniqueSuffix = uniqueString(resourceGroup().id, deployment().name)

// 1. ACR
module acr './01-acr.bicep' = {
  name: 'acrModule'
  params: {
    baseName: baseName
    location: location
    tags: tags
  }
}

// 2. Key Vault (fixed)
module keyVault './02-keyvault.bicep' = {
  name: 'keyVaultModule'
  params: {
    baseName: baseName
    location: location
    uniqueSuffix: uniqueSuffix
    tags: tags
  }
}

// 3. Cosmos DB
module cosmos './03-cosmos.bicep' = {
  name: 'cosmosModule'
  params: {
    baseName: baseName
    location: location
  }
}

// 4. Storage Account
module storage './04-storage.bicep' = {
  name: 'storageModule'
  params: {
    baseName: baseName
    location: location
    tags: tags
  }
}

// 5. AKS
module aks './05-aks.bicep' = {
  name: 'aksModule'
  params: {
    baseName: baseName
    location: location
    sshPublicKey: sshPublicKey
    acrName: acr.outputs.acrName
    adminUsername: adminUsername
  }
}

// Outputs
output acrLoginServer string = acr.outputs.acrLoginServer
output keyVaultName string = keyVault.outputs.keyVaultName
output cosmosAccountName string = cosmos.outputs.cosmosAccountName
output cosmosDatabaseName string = cosmos.outputs.cosmosDatabaseName
output cosmosContainerName string = cosmos.outputs.cosmosContainerName
output storageAccountName string = storage.outputs.storageAccountName
output aksName string = aks.outputs.aksName