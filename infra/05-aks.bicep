param baseName string
param location string
param sshPublicKey string
param adminUsername string = 'azureuser'

var aksName = toLower('${baseName}-aks')

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

        // ❌ remove spot, system pool cannot be spot
        enableNodePublicIP: false
      }
    ]

    linuxProfile: {
      adminUsername: adminUsername
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
