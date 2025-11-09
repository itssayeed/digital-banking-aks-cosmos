param baseName string
param location string

// Azure KV name must be <= 24 chars and alphanumeric
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
    // DO NOT add enableSoftDelete or enablePurgeProtection
    accessPolicies: []
  }
}

output keyVaultName string = keyVault.name
