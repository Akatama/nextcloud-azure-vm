param location string = 'Central US'

@description('The base name of the resource')
param resourceBaseName string

@description('Provide the administrator login name for the MySQL server.')
param administratorLogin string

@description('Provide the administrator login password for the MySQL server.')
@secure()
param administratorLoginPassword string

@description('name of the Vnet we will attach our VM to')
param vnetName string

@description('name of the Vnet resource group')
param vnetResourceGroup string


@description('The tier of the particular SKU. High Availability is available only for GeneralPurpose and MemoryOptimized sku.')
@allowed([
  'Burstable'
  'Generalpurpose'
  'MemoryOptimized'
])
param serverEdition string = 'Burstable'

@description('Server version')
@allowed([
  '5.7'
  '8.0.21'
])
param serverVersion string = '8.0.21'

@description('Availability Zone information of the server. (Leave blank for No Preference).')
param availabilityZone string = ''

@description('High availability mode for a server : Disabled, SameZone, or ZoneRedundant')
@allowed([
  'Disabled'
  'SameZone'
  'ZoneRedundant'
])
param haEnabled string = 'Disabled'

@description('Availability zone of the standby server.')
param standbyAvailabilityZone string = '2'

param storageSizeGB int = 120
param storageIops int = 360
@allowed([
  'Enabled'
  'Disabled'
])
param storageAutogrow string = 'Enabled'

@description('The name of the sku, e.g. Standard_D32ds_v4.')
param skuName string = 'Standard_B1ms'

param backupRetentionDays int = 7

@allowed([
  'Disabled'
  'Enabled'
])
param geoRedundantBackup string = 'Disabled'

param databaseName string = 'nextcloud'

var sqlServerName = '${toLower(resourceBaseName)}-mysqlserver'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroup)
}

resource mySQLServer 'Microsoft.DBforMySQL/flexibleServers@2023-06-30' = {
  name: sqlServerName
  location: location
  sku: {
    name: skuName
    tier: serverEdition
  }
  properties: {
    version: serverVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    availabilityZone: availabilityZone
    highAvailability: {
      mode: haEnabled
      standbyAvailabilityZone: standbyAvailabilityZone
    }
    storage: {
      storageSizeGB: storageSizeGB
      iops: storageIops
      autoGrow: storageAutogrow
    }
    network: {
      delegatedSubnetResourceId: virtualNetwork.properties.subnets[1].id
    }
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
  }
}

resource nextcloud_database 'Microsoft.DBforMySQL/flexibleServers/databases@2023-06-30' = {
  parent: mySQLServer
  name: databaseName
  properties: {
    charset: 'utf8mb4'
    collation: 'utf8mb4_general_ci'

  }
}
