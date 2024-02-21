## nextcloud-azure-vm-bicep
Automating the process of creating a Nextcloud instance on an Azure VM

This project is broken into multiple parts

To read my thoughts, which I wrote as I was working on each part of this project, see my_thoughts.md

### How to run

#### Part 3 High Availability (Main part of the project)

1. Create the resource groups you need. I used 3 of them, one for the virtual network (nextcloud-bicep-network), one for the storage account and the database (nextcloud-bicep-storage) and last for the servers and the Azure Load Balancer (nextcloud-bicep-server).
2. Deploy the virtualNetwork bicep file
3. Encrypt a file with ansible-vault in the following form
    db_password: <database_password>
    user_password: <admin_user_password>
4. Put your password for the file from step 3 into the ansible directory, and make sure it is named vault_pass
5. Run buildStorage.ps1 file. It will use the ansible-vault to get the db_password.
6. Run genKeyAndDeployServers.ps1 file. This will deploy all your servers and add the public IPs to ansible/static.ini
7. Call configureNextCloudandDB.yml for one of the VMs, making sure to provide the password file for the encrypted file
    ansible-playbook -e @nextcloud_passwords.enc --vault-password-file vault_pass configureNextCloudandDB.yml 
8. Call configureNextCloud.yml for the remaining VMs.
    ansible-playbook -e @nextcloud_passwords.enc --vault-password-file vault_pass configureNextCloud.yml 
9. Call secureVMs.ps1, which removes SSH access and the public IP from the VMs.

You can also set up a pipeline in Azure DevOps (or GitHub) to deploy all of this for you. You can see my example pipeline nextcloud-ha-bicep-config.yml. Note that this pipeline assumes you have already done parts 1-7, and does parts 8 and 9 with any number of Nextcloud servers you wish to create. I did this because I wanted to assume that the virtual network, storage account and database were already created.

pipeline variables you need to add:
db_name
location
numberOfVMs
password_salt (for nextcloud's config file)
secret (for nextcloud's config file)
resourceGroupName (for the servers)
storageAccount (the of the storage account)
storageResourceGroup
userName (user that we will create as the nextcloud admin)
vault_pass (for the db and user password, see step 3 and 4)
vmName (base name for the VMs)
vnetName
vnetResourceGroupName


#### Part 1 Base
1. Create the resource groups you need. As the VM server for this part handles the document storage and the database, the only other thing you will need to consider is how you handle the virtual network. So 1 or 2 depending on how you want to handle that.
2. Encrypt a file with ansible-vault in the following form
    db_password: <database_password>
    user_password: <admin_user_password>
3. Put your password for the ansible-vault encrypted file from step 2 into the ansible directory, and make sure it is named vault_pass.
4. Call genKeyAndCallBicep.ps1
5. Call configureNextCloud.yml. Note that this is more similar to configureNextCloudandDB.yml of Part 3
    ansible-playbook -e @nextcloud_passwords.enc --vault-password-file vault_pass configureNextCloud.yml

As before, I have provided an example pipeline for Azure DevOps called nextcloud-base-config.yml. 
Required pipeline variables:
vault password, so the pipeline can add it to the vault_pass file.

#### Part 2 Remiote DB
1. Create the resource groups you need. I used 3 of them, one for the virtual network (nextcloud-bicep-network), one for the storage account and the database (nextcloud-bicep-db) and last for the servers and the Azure Load Balancer (nextcloud-bicep-server).
2. Deploy the virtualNetwork bicep file
3. Encrypt a file with ansible-vault in the following form
    db_password: <database_password>
    user_password: <admin_user_password>
4. Put your password for the file from step 3 into the ansible directory, and make sure it is named vault_pass
5. Run buildStorage.ps1 file. It will use the ansible-vault to get the db_password.
6. Run genKeyAndDeployServers.ps1 file. This will deploy all your servers and add the public IPs to ansible/static.ini
7. Call configureNextCloud.yml. Note that this is more similar to configureNextCloudandDB.yml of Part 3
    ansible-playbook -e @nextcloud_passwords.enc --vault-password-file vault_pass configureNextCloud.yml

I have also provided a pipeline here, called nextcloud-db-config.yml. Note that this pipeline assumes you have already done parts 1-5, as I wanted to assume that the virtual network, storage account and database were already created.
Required pipeline variables:
vault password
right now, database URL and storage account info is hard coded into this step. I will update that, and when that happens we will need pipeline variables here.

#### Part 4 Disaster Recovery
In terms of having a working pipeline or series of steps that can be performed, this part was a failure. It was not a failure in the sense that I learned a lot, which is the true purpose of this project. To learn more, read my thoughts for this part in my_thoughts.md