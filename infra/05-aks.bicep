param baseName string
param location string
param sshPublicKey string
param acrName string
param adminUsername string = 'azureuser'

var aksName = toLower('${baseName}-aks')

resource aks 'Microsoft.ContainerService/managedClusters@2023-10-01' = {
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

    oidcIssuerProfile: {
      enabled: true
    }

    workloadIdentityProfile: {
      workloadIdentityEnabled: true
    }

    agentPoolProfiles: [
      {
        name: 'systempool'
        count: 1
        vmSize: 'Standard_B2s'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        mode: 'System'
        type: 'VirtualMachineScaleSets'
        enableAutoScaling: true
        minCount: 1
        maxCount: 3
        osDiskSizeGB: 30
        maxPods: 30
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
      networkPolicy: 'azure'
      loadBalancerSku: 'standard'
    }

    enableRBAC: true

    autoUpgradeProfile: {
      upgradeChannel: 'stable'
    }
  }
}

// Reference existing ACR
resource acrRes 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

// Assign AcrPull role to AKS
resource acrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, acrName, aks.name, 'acrpull')
  scope: acrRes
  properties: {
    principalId: aks.identity.principalId
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    )
  }
}

// Outputs
output aksName string = aks.name
output aksPrincipalId string = aks.identity.principalId