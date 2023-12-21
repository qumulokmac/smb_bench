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

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "virtual_network_name" {
  value = azurerm_virtual_network.vnet.name
}

output "subnet_name" {
  value = azurerm_subnet.subnet.name
}

output "public_ips" {
  value = "${azurerm_public_ip.publicip.*.ip_address}"
}

output "private_ips" {
  value = tomap({
    for name, vm in azurerm_network_interface.nic : name => vm.private_ip_address
  })
}

output "azurerm_windows_virtual_machine" {
  value = "${azurerm_windows_virtual_machine.vm.*.name}"
}
