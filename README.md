# smb_bench
SMB Benchmarking Framework leveraging [FIO](https://github.com/axboe/fio)
> Designed for Azure Native Qumulo SMB Benchmark testing

---

#### Included in this repository: 

- Terraform module to deploy the Azure vNet, resource group, subnet, NSG's, VM's, etc
- Bicep script to deploy a ANQ cluster
- Example FIO INI config files 
- Scripts to drive the process
- Helper scripts and `procexp64.exe` (a task manager alternative)


#### Architecture Diagram:
![SMB Bench Architecture Diagram](https://github.com/qumulokmac/smb_bench/blob/main/docs/smb_bench_diagram_anq.png)
---

#### Process to deploy and run an SMB benchmark: 

1. Deploy the environment
	- Update the terraform config file `variables.tf` *(in the smb_bench/terraform directory)* with the specific configuration values for the SMB benchmark you want to run.
	- Run: 
	    - `terraform init`
	    - `terraform plan -out tfstate`
	    - `terraform apply tfstate`
2. Deploy the ANQ cluster: 
	- Note: *Using Bicep until ANQ supports terraform*
	- Bicep: run bicep/deploy_anq.sh	
	- Create an SMB share and local user on the qumulo cluster 
		- `qq auth_add_user --name LOCALUSERNAME [-p [PASSWORD]]`
		- `qq auth_assign_role -r Administrators -t LOCALUSERNAME`
		- `qq smb_add_share --name YOURSHARENAME --fs-path /YOURSHARENAME --all-access`
3. *[Optional]* Create the Microsoft Remote Desktop (RDP) profiles following the instructions in the repository at ~/tools/rdp/README.md
4. Remote Desktop into the Maestro Windows Server
5. *[Optional]* Configure the Cygwin environment on the Maestro Windows Server
	- Create the vimfiles directory at `%userprofile%\vimfiles`
		- DOS: `mkdir  %userprofile%\vimfiles\`
		- Cygwin: `mkdir /cygdrive/c/Users/mrcooper/vimfiles/`
	- Copy the VIM config file: 
		- DOS: `copy ini/vimrc %userprofile%\vimfiles\`
		- Cygwin: `cp ~/ini/vimrc /cygdrive/c/Users/mrcooper/vimfiles/`
	- Close and re-open the cygwin window
6. Install smb_bench on Maestro Windows Server
	- You can `git clone` the [repo](https://github.com/qumulokmac/smb_bench), or just copy the files over manually from your desktop. 
7. Mount the share on Maestro Windows Server at A:\ for Administrative purposes 

	`net use /persist:yes A: \\CLUSTER_IP_ADDRESS\SHARENAME`

8.	Update the `nodes.conf` and `workers.conf` files with node/worker IP/names 
	- *Do not use comments or whitespace in the config files*
9.	Update the JSON configuration file (`smbbench_config.json`) with your benchmark details
- Be very specific when you choose a 'unique run identifier', this will be the top-level prefix in the result blob container
11.	In bash [Cygwin], run `smb_bench.sh` and monitor the output. 
12.	The results will be uploaded to the Azure Container 

---

### SMB Bench process workflow:

![SMB Bench Process Workflow](https://github.com/qumulokmac/smb_bench/blob/main/docs/smb_bench_process_workflow.png)

