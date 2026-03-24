param baseName string
param location string
param tags object = {}

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param skuName string = 'Basic'

// Ensure uniqueness + preserve suffix + respect 50 char limit
var uniqueSuffix = uniqueString(resourceGroup().id)
var acrBase = toLower('${baseName}acr')
var acrName = '${take(acrBase, 50 - length(uniqueSuffix))}${uniqueSuffix}'

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

output acrId string = acr.id
output acrName string = acr.name
output acrLoginServer string = acr.properties.loginServer