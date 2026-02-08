param baseName string
param location string
param uniqueSuffix string

var kvName = '${toLower(baseName)}-kv-${uniqueSuffix}'

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
    enableRbacAuthorization: true
    accessPolicies: []
  }
}

output keyVaultName string = keyVault.name
