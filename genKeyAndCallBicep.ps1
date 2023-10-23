$vmName = "nextCloudBicep"
$keyPath = $HOME + "/.ssh/"
$privateKeyName = $vmName + "-key"
$publicKeyName = $vmName + "-key.pub"
$privateKeyPath = $keyPath + "/" + $privateKeyName
$publicKeyPath  = $keyPath + "/" + $publicKeyName

# ssh-keygen -m PEM -t rsa -b 2048 -C $vmName -f $privateKeyPath -N ''

$sshKey = Get-Content $publicKeyPath
$secureSSHKey = ConvertTo-SecureString $sshKey -AsPlainText -Force

$resourceGroupName = "app-jlindsey2"
$location = "Central US"
$userName = "jimmy"
$vnetName = "ansible-test-vnet"

New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile ./bicep/virtualMachine.bicep -vmName $vmName `
    -location $location -vnetName $vnetName -adminUsername $userName -adminPasswordOrKey $secureSSHKey