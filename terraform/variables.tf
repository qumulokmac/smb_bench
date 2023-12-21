################################################################################
# 
# Windows   Server Benchmark Provisioning Terraform Module
# Date:     December 2nd, 2023
# Author:   kmac@qumulo.com
# Desc:     Provision multiple azurerm_windows_virtual_machine's leveraging a prebuilt image
#
# variables.tf:
#   1/ resource_group_location:     Which region to deploy in, E.g. "eastus"
#   2/ common_prefix:               String to be prepended to all cloud object names created in project
#   3/ num_vms:                     The number of VM's to deploy
#   4/ os_image_id                  Image ID to use for the windows OS build
#   5/ vmsize:  Virtual Machine Size to use, E.g. "Standard_D2s_v3"
#   6/ admin_username               Windows local admin username
#   7/ admin_password               Windows local admin password
#
# outputs.tf:
#   - resource_group_name
#   - virtual_network_name
#   - subnet_name
#   - public_ips
#   - private_ips
#   - azurerm_windows_virtual_machine's
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
  default     = "project-x"
}

variable "num_vms" {
  type        = number
  description = "Number of VM's"
  default     = 16
}

variable "vmsize" {
  type        = string
  description = "Virtual Machine Size for the Windows Servers"
  default     = "Standard_D16ls_v5"
}

variable "os_image_id" {
  type        = string
  description = "Windows Server 2019 FIO Image"
  default     = "/subscriptions/2f0fe240-4ebb-45eb-8307-9f54ae213157/resourceGroups/crucible/providers/Microsoft.Compute/galleries/product_build_images/images/windows-maestro"
}

variable "admin_username" {
  type        = string
  description = "Windows local admin username"
  default     = "youradmin"
}

variable "admin_password" {
  type        = string
  description = "Windows local admin password"
  default     = "yourpassword"
}
variable "powershell_script" {
  type        = string
  description = "Powershell Script"
  default     = "powershell_script.ps1"
}
