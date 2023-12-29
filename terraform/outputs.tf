################################################################################
# 
# Windows   Server Benchmark Provisioning Terraform Module
# Date:     December 2nd, 2023
# Author:   kmac@qumulo.com
# Desc:     Provision multiple azurerm_windows_virtual_machine's leveraging a prebuilt image
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
