# smb_bench
SMB Benchmarking Framework for Azure Native Qumulo leveraging [FIO](https://github.com/axboe/fio)
![SMB Bench Architecture Diagram](https://github.com/qumulokmac/smb_bench/blob/main/docs/smb_bench_diagram_anq.png)
---
### This document is still a work in progress (WIP)
---

# |                                           | 
# THIS README IS OUT OF DATE, KMac to update. |
# |                                           | 

##### Included in this repository: 

- Terraform module to deploy the Azure vNet, resource group, subnet, NSG's, VM's, etc
- Bicep script to deploy a ANQ cluster
- Example FIO INI config files 
- Scripts to drive the process
- Helper scripts and `procexp64.exe` (a task manager alternative)

#####Process to deploy and run an SMB benchmark: 

1. Deploy the environment
	- Terraform *(smb_bench/terraform directory)*
	- Modify variables.tf with your settings
	- Run: 
	- `terraform init`
	- `terraform plan -out tfstate`
	- `terraform apply tfstate`
2. Deploy the ANQ cluster: 
	- Note: *Using Bicep until ANQ supports terraform*
	- Bicep: run bicep/deploy_anq.sh	
	- Create an SMB share and local user on the qumulo cluster 
		- `qq auth_add_user --name NAME [-p [PASSWORD]]`
		- `qq auth_assign_role -r Administrators -t USERNAME`
		- `qq smb_add_share --name YOURSHARENAME --fs-path /YOURSHARENAME --all-access`
3. Create the Microsoft Remote Desktop (RDP) profiles following the instructions in the repository at ~/tools/rdp/README.md
4. Mount the SMB shares on all Windows clients
	- Log onto the "Maestro" Server
	- Update the nodes.conf and workers.conf files located in C:\FIO 
	- Run the powershell script [ONCE] `C:\FIO\rmount-q.ps1` 
	- This creates persistent mounts for every node on every client
	- Reboot all of the Windows Clients:
		`$ az vm restart --ids $(az vm list -g YOUR-RG --query "[].id" -o tsv)`
5. Configure the Cygwin environment on Maestro
	- Create the vimfiles directory at `%userprofile%\vimfiles`
		- DOS: `mkdir  %userprofile%\vimfiles\`
		- Cygwin: `mkdir /cygdrive/c/Users/mrcooper/vimfiles/`
	- Copy the VIM config file: 
		- DOS: `copy ini/vimrc %userprofile%\vimfiles\`
		- Cygwin: `cp ~/ini/vimrc /cygdrive/c/Users/mrcooper/vimfiles/`
	- Close and re-open the cygwin window
6. Install the smb_mount scripts on Maestro
	- You can git clone the repo or just copy the files over. 
	- Important directories needed are: ini & scripts
	- copy `make-fiojobs-one-fio.sh` to the home directory 
7. Configure smb_bench
	- Copy workers.conf & nodes.conf to ~/ini 
		- cygwin> cp -p /cygdrive/c/FIO/*.conf ~/ini
	- Create/modify YOUR global FIO template file in ~/ini
	- Edit the settings in `make-fiojobs-one-fio.sh`
	- Run ./make-fiojobs-one-fio.sh 
		- This creates all of the config files needed and copies them to the Qumulo cluster in the "stage" directory
8. Start the benchmark 
		- Open Powershell ISE on all Windows Workers
		- Load the `runall.ps1` powershell script from the scripts directory `C:\cygwin64\home\mrcooper\scripts\runall.ps1`
		- Once ready, click start on all workers *(until this is automated)*



