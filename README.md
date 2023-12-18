## nextcloud-azure-vm-bicep
Automating the process of creating a Nextcloud instance on an Azure VM

This project is broken into multiple parts

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
This part has done what I did in part_1_base, but I have seperated the server from the file storage and database. The database is Azure Database for MySQL flexible server. The file storage is utilizing Azure Blob storage with NSF v3 and Hierarchical namespaces enabled. Azure Blob storage with NSF v3 allows you to mount the blob storage onto a Linux machine, which then you can access as if it was a folder on the server.

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
Coming soon