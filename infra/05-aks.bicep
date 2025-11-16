param baseName string
param location string
param sshPublicKey string

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
        count: 1             // 1 node so cluster can start
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

output aksName string = aks.name
output aksPrincipalId string = aks.identity.principalId
