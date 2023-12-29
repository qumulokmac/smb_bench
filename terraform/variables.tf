################################################################################
# 
# Windows   Server Benchmark Provisioning Terraform Module
# Date:     December 2nd, 2023
# Author:   kmac@qumulo.com
#
################################################################################

variable "resource_group_location" {
  type        = string
  description = "Microsoft Region/Location"
  default     = "eastus"
}

variable "common_prefix" {
  type        = string
  description = "Prefix for all resources deployed by this project."
  default     = "YOUR_BENCHMARK_NAME_HERE"
}

variable "num_vms" {
  type        = number
  description = "Number of VM's"
  default     = 2
}

variable "vmsize" {
  type        = string
  description = "Virtual Machine Size for the Windows Servers"
  default     = "Standard_D2s_v3"
}

###
# This uses a prebuilt Windows Server instance with Cygwin and FIO installed, no antivirus, no firewall, WinRM configured
###
variable "os_image_id" {
  type        = string
  description = "Windows Server 2019 FIO Image"
  default     = "/subscriptions/2f0fe240-4ebb-45eb-8307-9f54ae213157/resourceGroups/crucible/providers/Microsoft.Compute/galleries/product_build_images/images/windows-maestro"
}

variable "admin_username" {
  type        = string
  description = "Windows local admin username"
  default     = "localadmin"
}

variable "admin_password" {
  type        = string
  description = "Windows local admin password"
  default     = "YOUR_PASSWORD_HERE"
}
