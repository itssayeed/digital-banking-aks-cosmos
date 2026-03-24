param baseName string
param location string
param uniqueSuffix string
param tags object = {}

var kvBase = toLower('${baseName}-kv')
var kvName = take('${kvBase}${uniqueSuffix}', 24)

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: kvName
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enablePurgeProtection: true
    enableRbacAuthorization: true
    publicNetworkAccess: 'Enabled'
    softDeleteRetentionInDays: 7
  }
}

output keyVaultName string = keyVault.name