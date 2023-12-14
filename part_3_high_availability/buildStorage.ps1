#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Uses Ansible-Vault to get the password for the SQL Server admin
    Then calls the Bicep file to build the SQL server

.Example
    ./buildStorage.ps1 -ResourceBaseName nextCloudBicep -ResourceGroupName app-jlindsey2 -Location "Central US" -VNetName nextcloud-bicep-vnet -DBdminName ncadmin
#>
param(
    [Parameter(Mandatory=$true)][string]$ResourceBaseName,
    [Parameter(Mandatory=$true)][string]$ResourceGroupName,
    [Parameter(Mandatory=$true)][string]$Location,
    [Parameter(Mandatory=$true)][string]$VNetName,
    [Parameter(Mandatory=$true)][string]$VnetResourceGroup,
    [Parameter(Mandatory=$true)][string]$DBAdminName
)

$mySQlServerName = $ResourceBaseName.ToLower()

# Use Ansible-Vault to get the db password
$passwords = ansible-vault view ./ansible/nextcloud_passwords.enc --vault-password-file ./ansible/vault_pass
$DBAdminPassword = ConvertTo-SecureString $passwords[0].split(":")[1].trim() -AsPlainText -Force

#-storageAccountSkuName "Premium_ZRS" -storageAccountKind "BlockBlobStorage"

New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -Name $ResourceBaseName -TemplateFile ./bicep/storage.bicep `
    -resourceBaseName $ResourceBaseName -location $Location -vnetName $VNetName -vnetResourceGroup $VnetResourceGroup `
    -storageAccountSkuName "Premium_LRS" -storageAccountKind "BlockBlobStorage" -serverEdition "GeneralPurpose" -haEnabled "SameZone" `
    -databaseSkuName "Standard_D2ds_v4" -geoRedundantBackup "Enabled" -administratorLogin $DBAdminName -availabilityZone "2"`
    -administratorLoginPassword $DBAdminPassword 

$requireSecureTransport = Update-AzMySqlFlexibleServerConfiguration -Name require_secure_transport -ResourceGroupName $ResourceGroupName `
    -ServerName $mySQlServerName -Value OFF

$dbYamlLine = "db_host: ${mySQlServerName}.mysql.database.azure.com"

$dbYamlLine > ./ansible/vars/db.yml