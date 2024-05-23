# SMB Bench
---
#### Harness for running a Windows benchmark at scale, designed to run with Azure Native Qumulo (ANQ)

*SMB Bench leverages [FIO](https://github.com/axboe/fio) for the storage load generator.*

## Table of Contents
1. [Azure Virtual Desktop (AVD) Benchmarking](#azure-virtual-desktop-avd-benchmarking)
2. [Included in this Repository](#included-in-this-repository)
3. [Architecture Diagram](#architecture-diagram)
4. [Process to Deploy and Run an SMB Benchmark](#process-to-deploy-and-run-an-smb-benchmark)
   1. [Prerequisites](#prerequisites)
   2. [Steps](#steps)
5. [SMB Bench Process Workflow](#smb-bench-process-workflow)
6. [About](#about)
7. [Resources](#resources)
8. [License](#license)
9. [Authors](#authors)

---

## Azure Virtual Desktop (AVD) Benchmarking

Azure Virtual Desktop (AVD) allows for the creation of virtual desktops and remote apps, providing a flexible and scalable way to deliver desktops and applications to users. Benchmarking AVD can help determine the performance and efficiency of the setup.

## Included in this Repository

- **Terraform Configuration**: Infrastructure as code for setting up the environment.
- **Userdata Scripts**: Scripts for customizing VMs.
- **Bicep Templates**: Templates for deploying resources.
- **Example FIO INI Config Files**: Configuration files for FIO.
- **Helper Scripts**: Scripts to aid the benchmarking process.

#### Architecture Diagram:
![SMB Bench Architecture Diagram](https://github.com/qumulokmac/smb_bench/blob/main/docs/smb_bench_diagram_anq.png)


## Process to Deploy and Run an SMB Benchmark
### Prerequisites
	
1. **Azure CLI**: Ensure Azure CLI is installed and configured.
2. **Terraform**: Ensure Terraform is installed.
3. **Bicep**: Ensure Bicep is installed for deploying resources.
	
---

### Steps


1. **Update Terraform Configuration**
   - Edit `variables.tf` in the `smb_bench/terraform` directory with your specific values.
   - Initialize Terraform:
     ```bash
     terraform init
     ```
   - Plan and apply the configuration:
     ```bash
     terraform plan -out tfstate
     terraform apply tfstate
     ```
	- Remember to configure the Blob properties for downloading the userdata script. 

2. **Upload Userdata Script**
   - Upload `~/scripts/smbbench-custom-data.ps1` to your Azure Blob container:
     ```bash
     az storage blob upload --container-name <container-name> --name smbbench-custom-data.ps1 --file `~/scripts/smbbench-custom-data.ps1'

		**The userdata script  `~/scripts/smbbench-custom-data.ps1` will configure the Windows server with all of the prerequisites needed to run this benchmark. **

3. **Deploy ANQ Cluster**
   - Use Bicep or another preferred method:
     ```bash
     bicep run bicep/deploy_anq.sh
     ```
   - Create an SMB share and local user on the Qumulo cluster:
     ```bash
     qq auth_add_user --name LOCALUSERNAME [-p [PASSWORD]]
     qq auth_assign_role -r Administrators -t LOCALUSERNAME
     qq smb_add_share --name YOURSHARENAME --fs-path /YOURSHARENAME --all-access
     ```

4. **Optional Configurations**
   - Create Microsoft Remote Desktop (RDP) profiles.
   - Configure the Cygwin environment on the Maestro Windows Server.
   - Create the vimfiles directory at `%userprofile%\vimfiles`:
     ```bash
     mkdir %userprofile%\vimfiles\
     cp ~/ini/vimrc /cygdrive/c/Users/qumulo/vimfiles/
     ```
   - Close and re-open the Cygwin window.

5. **Install the smb_bench Repository**
   - Remote Desktop into the Maestro Windows Server.
   - Clone the repository or copy the files manually:
     ```bash
     git clone https://github.com/qumulokmac/smb_bench.git
     ```

6. **Mount the Automation SMB Share**
   - Mount the share on the Maestro Windows Server:
     ```bash
     net use /persist:yes A: \\CLUSTER_IP_ADDRESS\YOURSHARENAME
     ```
     
7. **Configure Node and Worker Config Files**
   - Update `nodes.conf` and `workers.conf` with node/worker IP/names.	- *Do not use comments or whitespace in the config files*

8. **Configure the Main smbbench Config File (JSON)**:
   - Update `smbbench_config.json` with your benchmark details.
	- Be very specific when you choose a 'unique run identifier'; this will be the top-level prefix in the result blob container

9. **Execution**
   - Using Cygwin, run the benchmark:
     ```bash
     ~/smb_bench.sh
     ```

10. **Results**
    - Results will be uploaded to the Azure Container configured in `smbbench_config.json`.
    - Use `~/scripts/analyze-fiologs.sh` or load them into a spreadsheet/database for analysis.

---

### Security Disclaimer

- This script is intended for benchmarking; thus, security takes a back seat. It is *IMPORTANT* that you keep the harness in an environment that cannot be accessed externally except by you or any other testers
- This can be done by entering your IP address(es) into the terraform `variables.conf` file by editing the variable "authorized_ip_addresses".
- In order to be able to remote desktop into dozens of windows servers that have remotely mounted SMB shares themselves, we need to disable the firewall, Windows defender, and other actions that are not safe to do in a production environment. 
- Be sure to `terraform destroy` the environment as soon as you are finished and collected all of the results.

---

#### Powershell Double-hop

What is the double-hop issue? Microsoft has it documented [here](https://learn.microsoft.com/en-us/powershell/scripting/learn/remoting/ps-remoting-second-hop?view=powershell-7.40), but here is a layman's explanation:

- You need 'XXX' credentials to log into server "A"
- Those credentials can be used to log onto remote server "B"
- But if remote server "B" has its own remote server "C" SMB shares mounted, the original server "A" is not allowed to access the remote server "C" resources.
- One method around this is to use the Credential Security Support Provider (CredSSP) for authentication.
- Specific care was used to funnel all remote server "B" actions into a separate script (called WorkerScript.ps1) invoked in smb_bench.
     - The actions include mounting the SMB shares, executing the FIO commands, and copying the results to a shared drive.

---

#### Note on Azure Virtual Desktops (AVD)

Utilizing [smb_bench](https://github.com/qumulokmac/smb_bench#readme) to benchmark Azure Virtual Desktops (AVD) with Azure Native Qumulo (ANQ).

- Microsoft recommends using [FSLogix](https://learn.microsoft.com/en-us/azure/virtual-desktop/fslogix-containers-azure-files) with AVD for serving user profiles.
- FSLogix stores individual user profiles in a VHD/VHDX container dynamically attached to the virtual desktop at user login.
- AVD user access patterns transform into a predominantly write-heavy workload as statically read content is [cached locally](https://learn.microsoft.com/en-us/fslogix/concepts-fslogix-cloud-cache).
- Qumulo tested using direct examples from unnamed customer workloads.
  - This should closely match live production workloads running thousands of desktops on ANQ.
  - The typical workflow demands 90-95% 20KiB writes during the business day, requiring ~5-15 IOPS per user, depending on the user's intensity.
  - Ensure that the ANQ filesystem is in the same region and zone as the AVD session host VMs.

***Note:*** Azure Native Qumulo (ANQ) underwent testing to simulate thousands of users logging in concurrently to replicate an early morning "login storm." This test was conducted using [smb_bench](https://github.com/qumulokmac/smb_bench#readme) and can be reproduced using a default ANQv2 cluster with the [AVD FIO workload definition](https://github.com/qumulokmac/smb_bench/blob/main/examples/AVD_example_workload.ini) configured for 256 JPC (Jobs Per Client).

---

## About

This repository provides a framework for benchmarking SMB performance in an Azure environment. It includes scripts and templates for setting up the necessary infrastructure and running benchmarks.


## Resources

- [Azure Virtual Desktop Documentation](https://docs.microsoft.com/en-us/azure/virtual-desktop/)
- [Terraform Documentation](https://www.terraform.io/docs/)
- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Authors

- [kmac@qumulo.com](mailto:kmac@qumulo.com)
- Shiela

*Date: May 22, 2024*
