################################################################################
#
# Copyright (c) 2022 Qumulo, Inc. All rights reserved.
#
# NOTICE: All information and intellectual property contained herein is the
# confidential property of Qumulo, Inc. Reproduction or dissemination of the
# information or intellectual property contained herein is strictly forbidden,
# unless separate prior written permission has been obtained from Qumulo, Inc.
#
#
# Name:     SMB_Bench 2204 Terraform variables.tf
# Date:     May 8th, 2024
# Author:   kmac@qumulo.com
#
################################################################################

variable "common_prefix" {
  type        = string
  description = "Prefix for all resources deployed by this project."
  default     = "smbbench"
}

variable "num_vms" {
  type        = number
  description = "Number of VM's"
  default     = 1 
}

variable "vmsize" {
  type        = string
  description = "Virtual Machine Size for the Servers"
  # default     = "Standard_E32ds_v5"
  default     = "Standard_E8ds_v5"
}

variable "admin_username" {
  type        = string
  description = "Local admin username"
  default     = "qumulo"
}
variable "rgname" {
  type        = string
  description = "RG Name "
  default     = "RESOURCE_GROUP_NAME"
}
variable "location" {
  type        = string
  description = "Microsoft Region/Location"
  default     = "REGION"
}

variable "zone" {
  type        = string
  description = "Zone in the region you would like to deploy the Azure Native Qumulo cluster in"
  default     = "ZONE"
}

variable "worker_subnet" {
  type        = string
  description = "Subnet to deploy worker VM's too - should be in the same vNet as the ANQ cluster"
  default     = "SUBNET_ID"
}

variable "authorized_ip_addresses" {
  type        = list
  description = "Ip addresses for the workstations that need access to the harness"
  default     = ["IP_ADDRESS/32"]
}

variable "admin_password" {
  type        = string
  description = "Windows local admin password"
  default     = "PASSWORD"
}
