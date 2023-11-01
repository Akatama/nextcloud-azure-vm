#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Updates the Scale Set Pool to be associated with the Azure Virutal Machine Scale Sets

.DESCRIPTION
    First we call the function Get-ScaleSetPools to get a designated scale set
    Then we filter out the Scale Set Pools via the azureId field
    Then we call Update_ScaleSetPool to update it with the appropriate information

.Example
    ./Update-ScaleSetPools.ps1 -OrganizationUrl "https://dev.azure.com/jimmyl0495" -PATToken <Your_PAT_Token> -PoolId 16
#>
param(
    [Parameter(Mandatory=$true)][string]$VMName,
    [Parameter(Mandatory=$true)][string]$ResourceGroupName,
    [Parameter(Mandatory=$true)][string]$Location,
    [Parameter(Mandatory=$true)][string]$UserName,
    [Parameter(Mandatory=$true)][string]$VNetName
)

$publicIPName = "${vmName}-PublicIP"

$keyPath = $HOME + "/.ssh/"
$privateKeyName = $VMName + "-key"
$publicKeyName = $VMName + "-key.pub"
$privateKeyPath = $keyPath + "/" + $privateKeyName
$publicKeyPath  = $keyPath + "/" + $publicKeyName

#ssh-keygen -m PEM -t rsa -b 2048 -C $vmName -f $privateKeyPath -N ''

$sshKey = Get-Content $publicKeyPath
$secureSSHKey = ConvertTo-SecureString $sshKey -AsPlainText -Force

New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile ./bicep/virtualMachine.bicep -vmName $VMName `
    -location $Location -vnetName $VNetName -adminUsername $UserName -adminPasswordOrKey $secureSSHKey

$publicIP = Get-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Name $publicIPName

$staticIniLine = "${publicIP.IpAddress} ansible_ssh_private_key_file=${privateKeyPath}"

$staticIniLine > ./ansible/static.ini