#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Generates a public and private SSH key
    Then passes it to the Bicep file in this repo to create a virtual machine scale set that we can access with that key

.DESCRIPTION
    Generates a public and private SSH key
    Then passes it to the Bicep file in this repo to create a virtual machine scale set that we can access with that key

.Example
    ./genKeyAndCallBicep.ps1 -VMName nextCloudBicep -ResourceGroupName app-jlindsey2 -Location "Central US" -UserName jimmy -DBdminName ncadmin
#>
param(
    [Parameter(Mandatory=$true)][string]$VMName,
    [Parameter(Mandatory=$true)][string]$ResourceGroupName,
    [Parameter(Mandatory=$true)][string]$Location,
    [Parameter(Mandatory=$true)][string]$UserName,
    [Parameter(Mandatory=$true)][string]$VNetName,
    [Parameter(Mandatory=$true)][string]$VNetResourceGroup,
    [Parameter(Mandatory=$true)][int]$numberOfVMs
)

$publicIPName = "${vmName}-PublicIP"

$keyPath = $HOME + "/.ssh/"
$privateKeyName = $VMName + "-key"
$publicKeyName = $VMName + "-key.pub"
$privateKeyPath = $keyPath + $privateKeyName
$publicKeyPath  = $keyPath + $publicKeyName

$privateKeyPath

ssh-keygen -m PEM -t rsa -b 2048 -C $vmName -f $privateKeyPath -N '""'

$sshKey = Get-Content $publicKeyPath
$secureSSHKey = ConvertTo-SecureString $sshKey -AsPlainText -Force

# New-AzResourceGroup -Name $ResourceGroupName -Location $Location

New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -Name $VMName -TemplateFile ./bicep/virtualMachine.bicep -vmName $VMName `
    -location $Location -vnetName $VNetName -vnetResourceGroup $VNetResourceGroup -adminUsername $UserName -adminPasswordOrKey $secureSSHKey `
    -itemCount $numberOfVMs

$staticIniLines = ""
for($i=0; $i -lt $numberOfVms; $i++)
{
    $publicIP = (Get-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Name "${publicIPName}${i}").IpAddress

    $staticIniLines += "${publicIP} ansible_ssh_private_key_file=${privateKeyPath} ansible_user=${UserName}\n"
}

$staticIniLines > ./ansible/static.ini