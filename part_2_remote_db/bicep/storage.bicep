@description('Name of the virtual machine that we will create')
param resourceBaseName string

param location string = 'Central US'

@description('name of the Vnet we will attach our VM to')
param vnetName string

@description('name of the Vnet resource group')
param vnetResourceGroup string

@description('Sku of the storage account')
param skuName string = 'Standard_LRS'

@description('The kind of storage that the storage account will use. Is limited to General-Purpose V2 for Standrad and BlockBlobStorage for Premium')
@allowed([
  'StorageV2'
  'BlockBlobStorage'
])
param storageAccountKind string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroup)
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: '${resourceBaseName}storage'
  location: location
  sku: {
    name: skuName
  }
  kind: storageAccountKind
  properties: {
    allowBlobPublicAccess: true
    allowCrossTenantReplication: false
    allowedCopyScope: 'AAD'
    isHnsEnabled: true
    isLocalUserEnabled: true
    isNfsV3Enabled: true
    isSftpEnabled: false
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          action: 'Allow'
          id: virtualNetwork.properties.subnets[0].id
        }
      ]
    }
    publicNetworkAccess: 'Enabled'
    routingPreference: {
      routingChoice: 'MicrosoftRouting'
    }
    supportsHttpsTrafficOnly: true
  }
  resource blobService 'blobServices@2023-01-01' = {
    name: 'default'
    properties: {
      containerDeleteRetentionPolicy: {
        allowPermanentDelete: true
        days: 1
        enabled: true
      }
      isVersioningEnabled: false
    }
    resource blobContainer 'containers@2023-01-01' = {
      name: 'nextcloud'
      properties: {
        publicAccess: 'Blob'
        metadata: {}
      }
    }
  }
}
