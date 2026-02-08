param baseName string = 'dbanking'
param location string = 'southindia'
param uniqueSuffix string

@description('SSH public key for AKS nodes')
param sshPublicKey string

// 1. ACR
module acr './01-acr.bicep' = {
  name: 'acrModule'
  params: {
    baseName: baseName
    location: location
  }
}

// 2. Key Vault
module keyVault './02-KeyVault.bicep' = {
  name: 'keyVaultModule'
  params: {
    baseName: baseName
    location: location
	uniqueSuffix: uniqueSuffix
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
  }
}

// 5. AKS (ACR RBAC handled inside AKS module)
module aks './05-aks.bicep' = {
  name: 'aksModule'
  params: {
    baseName: baseName
    location: location
    sshPublicKey: sshPublicKey
    acrName: acr.outputs.acrName
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
