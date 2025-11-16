param baseName string
param location string

var suffix = toLower(substring(uniqueString(subscription().id, baseName), 0, 5))
var kvName = '${toLower(baseName)}kv${suffix}'

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: kvName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableSoftDelete: true
    enablePurgeProtection: true
    accessPolicies: []
  }
}

output keyVaultName string = keyVault.name
