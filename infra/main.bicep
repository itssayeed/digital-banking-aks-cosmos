param baseName string = 'dbanking'
param location string = 'southindia'
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

// 5. AKS (no ACR role assignment here)
module aks './05-aks.bicep' = {
  name: 'aksModule'
  params: {
    baseName: baseName
    location: location
    sshPublicKey: sshPublicKey
  }
}

// Convert ACR module output → usable resource reference
resource acrRes 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: acr.outputs.acrName
}

// Bind AKS -> ACR (AcrPull)
resource acrAksPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aks.outputs.aksPrincipalId, acr.outputs.acrId, 'acrpull')
  scope: acrRes
  properties: {
    principalId: aks.outputs.aksPrincipalId
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    )
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
