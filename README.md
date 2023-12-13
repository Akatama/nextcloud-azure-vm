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
* A PowerShell script which generates a new SSH Key, then takes all the parameters and calls the Bicep file.
* An Ansible Playbook
* An Ansible Vault encypted password file, which contains the password for both the database admin and the first user of Nextcloud
* An Ansible Configuration file, along with a static.ini for inventory
* A few files that the Ansible Playbook needs, such as the nextcloud.conf.j2 and config.php.j2

### part_3_high_availability
Coming soon

### part_4_disaster_recovery
Coming soon