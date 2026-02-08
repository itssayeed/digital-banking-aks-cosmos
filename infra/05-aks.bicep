param baseName string
param location string
param sshPublicKey string
param acrName string

var aksName = '${baseName}-aks'

resource aks 'Microsoft.ContainerService/managedClusters@2023-03-01' = {
  name: aksName
  location: location

  sku: {
    name: 'Base'
    tier: 'Free'
  }

  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    dnsPrefix: '${baseName}-dns'

    agentPoolProfiles: [
      {
        name: 'systempool'
        count: 1
        vmSize: 'Standard_B2s'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        mode: 'System'
        enableAutoScaling: true
        minCount: 1
        maxCount: 1
      }
    ]

    linuxProfile: {
      adminUsername: 'azureuser'
      ssh: {
        publicKeys: [
          {
            keyData: sshPublicKey
          }
        ]
      }
    }

    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
    }

    enableRBAC: true
  }
}

resource acrRes 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: acrName
}

resource acrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, acrName, aks.name, 'acrpull')
  scope: acrRes
  properties: {
    principalId: aks.identity.principalId
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull
    )
  }
}

output aksName string = aks.name
output aksPrincipalId string = aks.identity.principalId
