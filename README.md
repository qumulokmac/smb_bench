# smb_bench
SMB Benchmarking Framework leveraging [FIO](https://github.com/axboe/fio)
> Designed for Azure Native Qumulo SMB Benchmark testing for workloads such as AVD

---
#### Azure Virtual Desktop (AVD) Benchmarking
Using [smb_bench](https://github.com/qumulokmac/smb_bench#readme) to benchmark Azure Virtual Desktops (AVD) with Azure Native Qumulo (ANQ):

> - Microsoft recommends using FSLogix with their AVD service for serving user profiles.  
> - FSLogix stores individual users profile in a VHD/VHDX container which is dynamically attached to the virtual desktop at user login. 
> - The user acess pattern quickly turns into 95% writes, as statically read content is cached locally. 
> - Qumulo tested using direct examples from unnamed customers workloads. 
>    - This should closely match live production workloads running thousands of desktops on ANQ.
>    - It is common to see the workflow demand 90-95% writes during daily operations at approximately 5-15 IOPS per user, depending on the users intensitiy.

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
2. Deploy the ANQ cluster and create a local administrative user account: 
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

	`net use /persist:yes A: \\CLUSTER_IP_ADDRESS\YOURSHARENAME`

8.	Update the `nodes.conf` and `workers.conf` files with node/worker IP/names 
	- *Do not use comments or whitespace in the config files*
9.	Update the JSON configuration file (`smbbench_config.json`) with your benchmark details
- Be very specific when you choose a 'unique run identifier', this will be the top-level prefix in the result blob container
11.	In bash [Cygwin], run `smb_bench.sh` and monitor the output. 
12.	The results will be uploaded to the Azure Container 

---
### Note regarding powershell and the "double-hop" security restriction

This script is intended to be used for benchmarking, thus security has a back-seat.  In order to remote into dozens of windows servers that have remotely mounted SMB shares themselves, you have to solve the double-hop problem.  This has been done for you in this script. 

What is the double-hop issue? Microsoft has it documented [here](https://learn.microsoft.com/en-us/powershell/scripting/learn/remoting/ps-remoting-second-hop?view=powershell-7.40) but here is a laymans explanation: 

- You need 'X' credentials to log into server "A" 
- Those credentials can be used to log onto remote server "B"
- But if remote server "B" has its own remote server "C" SMB shares mounted, original server "A" is not allowed to access the remote server "C" resources. 
- One method around this is to use the Credential Security Support Provider (CredSSP) for authentication.
- Specific care was used to funnel all remote server "B" actions into a seperate script (called WorkerScript.ps1) invoked in smb_bench. 
     - The actions include mounting the SMB shares, executing the FIO commands, and copying the results to a shared drive. 

### SMB Bench process workflow:

![SMB Bench Process Workflow](https://github.com/qumulokmac/smb_bench/blob/main/docs/smb_bench_process_workflow.png)

