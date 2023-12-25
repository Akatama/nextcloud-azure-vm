## nextcloud-azure-vm-bicep
Automating the process of creating a Nextcloud instance on an Azure VM

This project is broken into multiple parts

### How to run
The below assumes using part 3, as that is the most significant work I did on this project. However, it is similar to part 1 and 2.

1. Create the resource groups you need. I used 3 of them, one for the virtual network (nextcloud-bicep-network), one for the storage account and the database (nextcloud-bicep-storage) and last for the servers and the Azure Load Balancer (nextcloud-bicep-server).
2. Deploy the virtualNetwork bicep file
3. Encrypt a file with ansible-vault in the following form
    db_password: <database_password>
    user_password: <admin_user_password>
4. Put your password for the file from step 3 into the password directory, and make sure it is named nextcloud_passwords.enc
5. Run buildStorage.ps1 file. It will use the ansible-vault to get the db_password.
6. Run genKeyAndDeployServers.ps1 file. This will deploy all your servers and add the public IPs to ansible/static.ini
7. Call configureNextCloudandDB.yml for one of the VMs, making sure to provide the password file for the encrypted file
8. call configureNextCloud.yml for the remaining VMs.

You can also set up a pipeline in Azure DevOps (or GitHub) to deploy all of this for you. For my purposes, I decided that the virtual network, storage account and database would already be deployed previous to deploying the Nextcloud servers. So nextcloud-ha-bicep-config.yml only deploys the servers, sets them up and then calls secureVMs.ps1 to remove the public IPs from the VMs and remove the SSH rule from the network security group. Note that I made extensive use of pipeline variables, as there are a lot of things I didn't want to add to GitHub (e.g. the password for the Ansible-vault encrypted file, the fully-qualified domain name for the database, ect). The advatnage of this is that it is relatively easy to change a few variables before you run the pipeline so you can deploy to whatever resource group or locations you want.

### part_1_base
This part has all the files necessary to install nextcloud on an Ubuntu server, with the assumption that we will use Azure DevOps. This includes database itself, so this wouldn't be very good if you need high availability or disaster recovery options. However, as I am using this project to learn, it was a very good opportunity for me to learn about configuration management.

If you don't want to use a pipeline to deploy this, using the provided genKeyAndCallBicep.ps1 PowerShell script (or manually doing the same steps as shown in the PowerShell script) with the Ansible files will succeed in installing Nextcloud and properly setting up everything.

Included here:
* A Bicep file to deploy the VM, which includes an NSG and public IP. Currently this bicep file connects to an already existing VNet
* A PowerShell script which generates a new SSH Key, then takes all the parameters and calls the Bicep file.
* An Ansible Playbook
* An Ansible Vault encypted password file, which contains the password for both the database admin and the first user of Nextcloud
* An Ansible Configuration file, along with a static.ini for inventory
* A few files that the Ansible Playbook needs, such as the nextcloud.conf and config.php.j2

### part_2_remote_db
This part has done what I did in part_1_base, but I have seperated the server from the file storage and database. The database is Azure Database for MySQL flexible server. The file storage is utilizing Azure Blob storage with NFS v3 and Hierarchical namespaces enabled. Azure Blob storage with NFS v3 allows you to mount the blob storage onto a Linux machine, which then you can access as if it was a folder on the server.

Included here:
* A Bicep file to deploy the virtual network configuration, which includes a subnet set up for the Azure Database for MySQL flexible server (including adding the server Microsoft.DBforMySQL/flexibleServers) as well as a subnet for the server and Azure blob storage
* A Bicep file for deploying the Azure Database for MySQL flexible server
* A Bicep file for deploying the Azure Blob storage
* A Bicep file to deploy the VM, which includes an NSG and public IP. Currently this bicep file connects to the virtual network deployed in the first Bicep file.
* A PowerShell script which gets the Database Admin password from nextcloud_passwords.enc using Ansible-Vault, deploys the Azure Database for MySQL flexible server, then turns off require_secure_transport from the Database for MySQL flexible server configuration.
* A PowerShell script which generates a new SSH Key, then takes all the parameters and calls the Bicep file that creates the VM and associated resources.
* An Ansible Playbook
* An Ansible Vault encypted password file, which contains the password for both the database admin and the first user of Nextcloud
* An Ansible Configuration file, along with a static.ini for inventory
* A few files that the Ansible Playbook needs, such as the nextcloud.conf.j2 and config.php.j2

### part_3_high_availability
The goal of this part was to use high available features for Azure Database for MySQL flexible server and Azure Blob storage, along with a Auzre Load Balancer with a backend pool for 3 virtual machines that are in an Availability Set. However, while 3 virtual machines is what I tested, it would take no changes to create more, provided that the purpose was for all VMs to belong to the same backend pool. Only a small amount of work would be required if we wanted to have multiple backend pools for the Azure Load Balancer. 

I do want to note, that since Nextcloud is a stateful app, the Azure Load Balancer's load balancing rule has been set to "SourceIPProtocol" for both the HTTP and HTTPS version of the load balancing rule. This makes it so that once we have a connection to one of the servers, we maintain that same connection, and as a result don't get directed to another server where we haven't logged in yet. Of course, this does mean there could be potential problems for properly balancing the load, as if servers B and C  have people using them for only short durations, while server A has people using it for long durations, then server A might start to get overloaded. Still, with an app like Nextcloud, at least in its current form, this is just something you would have to keep an eye on.

Included here:
* A Bicep file to deploy the virtual network configuration, which includes a subnet set up for the Azure Database for MySQL flexible server (including adding the server Microsoft.DBforMySQL/flexibleServers) as well as a subnet for the server, Azure blob storage, Availability Set and Azure Load Balancer
* A Bicep file for deploying the Azure Database for MySQL flexible server and Azure Blob Storage
* A Bicep file to deploy the multiple VMs, with an NSG, Public IPs and NICs, an Availability Set that is attached to each VM, and finally an Azure Load Balancer with all required rules that are properly attached to the VMs NICs. Optionally, you can set up DDoS protection on the Azure Load Balancer. 
* A PowerShell script which gets the Database Admin password from nextcloud_passwords.enc using Ansible-Vault, and then calls the Bicep file for deploying the Azure Database for MySQL flexible server and Azure Blob Storage, then turns off require_secure_transport from the Database for MySQL flexible server configuration.
* A PowerShell script which generates a new SSH Key, then takes all the parameters and calls the Bicep file that creates the VMs, Availability Set, Azure Load Balancer and associated resources.
* An Ansible Playbook that configures a VM for Nextcloud and the Nextcloud database, then attaches it to both the database and Azure blob storage acccount.
* An Ansible Playbook that configures a VM for Nextcloud, then attaches it to both the already-configured database and Azure blob storage account. Note that in order to not create unncessary Nextcloud Admin users, we set up a temporary database on the VM before removing it at the end after attaching it to the proper database.
* An Ansible Vault encypted password file, which contains the password for both the database admin and the first user of Nextcloud
* An Ansible Configuration file, along with a static.ini for inventory
* A few files that the Ansible Playbook needs, such as the nextcloud.conf.j2 and config.php.j2

### part_4_disaster_recovery
I did work on this, but unfortunately there were several probleems that made it difficult.

First, the Storage Account I used for Part 3 cannot use Vaulted Backup, because I require the use of NFSv3. This means that it is not possible to backup the Storage Account to another region using only Azure services. Vaulted Backup is a service that is in public preview, so it is possible that I will be able to do so in the future. If that is the case, then Part 4 will have an update.

Second, when I tried to use Azure Site Recovery on the Ubuntu servers, I found that version of Ubuntu I was using cannot be used for ASR because their version of the Linux kernel is not supported. This is strange, because Ubuntu currently uses Linux Kernel 6.2, which is not new. However, documentation shows that only the Linux kernel 5.15 is supported. I tried to look for a version of Ubuntu Linux server that used a older version of the kernel, but none seem to exist on Azure anymore. I have asked a question on Microsoft Learn to see if there is anything else I can do. Otherwise, I would have to use a more recent version of Ubuntu, then downgrade to an older kernel, then make my own VM image.

Last, it appears that while the geo-redundant backup for the Database worked, it caused problems during setup as Nextcloud expected files to exist that didn't exist in the completely new Storage Account I had to create to test out disaster recovery.

Unfortunately, since by definition Disaster Recovery is something you set up and then use it possibly months or years later, there really isn't a good way to automate it setting up. I did what I could to set it up, but I did so in the Azure portal. There is documentation for all of the steps I tried on Microsoft Learn using Azure CLI or the AZ PowerShell module, as a note.

Included here:
* main.bicep - Same file that deploys the servers as in part 3
* storageAccount.bicep - Deploys a brand new storage account
* virtualNetwork.bicep - Deploys the virtual network.