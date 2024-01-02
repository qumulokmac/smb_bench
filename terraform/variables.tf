################################################################################
# 
# Windows   Server Benchmark Provisioning Terraform Module
# Date:     December 2nd, 2023
# Author:   kmac@qumulo.com
# Desc:     Provision multiple azurerm_windows_virtual_machine's leveraging a prebuilt image
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
  default     = "XXXXXX"
}

variable "num_vms" {
  type        = number
  description = "Number of VM's"
  default     = NN
}

variable "vmsize" {
  type        = string
  description = "Virtual Machine Size for the Windows Servers"
  default     = "YourPreferredSize
}

variable "os_image_id" {
  type        = string
  description = "Windows Server 2019 FIO Image"
  default     = "XXXXXX"
}

variable "admin_username" {
  type        = string
  description = "Windows local admin username"
  default     = "localadmin"
}

variable "admin_password" {
  type        = string
  description = "Windows local admin password"
  default     = "XXXXXX"
}
variable "remote_allow_ipaddress" {
  type        = string
  description = "IP Address for remote admin access for SSH/RDP/HTTP/HTTPS"
  default     = "XXXXXX"
}
variable "anq_vnet_network_id" {
  type        = string
  description = "VNet ID for the ANQ network, for peering the networks"
  default     = "XXXXXX"
}
variable "anq_resourcegroup" {
  type        = string
  description = "Resourcegroup that the ANQ cluster resides in, for peering the networks"
  default     = "XXXXXX"
}
variable "anq_vnet" {
  type        = string
  description = "vNet Name for the ANQ Network, for peering the networks"
  default     = "XXXXXX"
}
