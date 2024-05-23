################################################################################
# 
# Windows   Server Benchmark Provisioning Terraform Module
# Date:     December 2nd, 2023
# Author:   kmac@qumulo.com
# Desc:     Provision multiple azurerm_windows_virtual_machine's leveraging a prebuilt image
#
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


output "workers_virtual_machine_id" {
  description = "Workers Virtual Machine ID"
  value = "${azurerm_windows_virtual_machine.windows_vm.*.name}"
}


output "maestro_virtual_machine_id" {
  description = "Maestro Virtual Machine ID"
  value = "${azurerm_windows_virtual_machine.maestro_vm.name}"
}

##########################################################################################
# Output IP Addresses
##########################################################################################

output "workers_private_ip_addresses" {
  description = "Workers Private IP Addresses"
    value = "${azurerm_windows_virtual_machine.windows_vm.*.private_ip_address}"
}

output "maestro_private_ip_address" {
  description = "Maestro Private IP Address"
    value = "${azurerm_windows_virtual_machine.maestro_vm.private_ip_address}"
}

output "maestro_public_ip_address" {
  description = "Maestros Public IP Address"
  value = azurerm_public_ip.maestro_publicip.ip_address
}
