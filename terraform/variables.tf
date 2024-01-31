################################################################################
variable "resource_group_location" {
  type        = string
  description = "Microsoft Region/Location"
  default     = "region"
}

variable "common_prefix" {
  type        = string
  description = "Prefix for all resources deployed by this project."
  default     = "yourdemo"
}

variable "num_vms" {
  type        = number
  description = "Number of VM's"
  default     = 4
}

variable "vmsize" {
  type        = string
  description = "Virtual Machine Size for the Windows Servers"
  default     = "Standard_D16ls_v5"
}

variable "os_image_id" {
  type        = string
  description = "Windows Server 2019 Image with no firewall, defender, antivirus, and WSman trusted"
  default     = "/subscriptions/YOURSUB/resourceGroups/YOURRG/providers/Microsoft.Compute/galleries/YOURGALLERY/images/smb_bench" 
}

variable "worker_subnet" {
  type        = string
  description = "Subnet to deploy worker VM's too - should be in the same vNet as the ANQ cluster"
  default     = "/subscriptions/YOURSUB/resourceGroups/YOURRG/providers/Microsoft.Network/virtualNetworks/YOURVNET/subnets/workers"
}


variable "admin_username" {
  type        = string
  description = "Windows local admin username"
  default     = "qumulo"
}

variable "admin_password" {
  type        = string
  description = "Windows local admin password"
  default     = "YOURPASSWORD"
}
variable "remote_allow_ipaddress" {
  type        = string
  description = "IP Address for remote admin access for SSH/RDP/HTTP/HTTPS"
  default     = "YOUR_IPADDRESS"
}
variable "anq_vnet_network_id" {
  type        = string
  description = "VNet ID for the ANQ network, for peering the networks"
  default     = "/subscriptions/YOURSUB/resourceGroups/YOURRG/providers/Microsoft.Network/virtualNetworks/YOURVNET"
}
variable "anq_resourcegroup" {
  type        = string
  description = "Resourcegroup that the ANQ cluster resides in, for peering the networks"
  default     = "YOURRG"
}
