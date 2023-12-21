################################################################################
# 
# Windows   Server Benchmark Provisioning Terraform Module
# Date:     December 2nd, 2023
# Author:   kmac@qumulo.com
# Desc:     Provision multiple azurerm_windows_virtual_machine"s leveraging a prebuilt image
#
# variables.tf:
#   1/ resource_group_location:     Which region to deploy in, E.g. "eastus"
#   2/ common_prefix:               String to be prepended to all cloud object names created in project
#   3/ num_vms:                     The number of VM"s to deploy
#   4/ os_image_id                  Image ID to use for the windows OS build
#   5/ vmsize:                      Virtual Machine Size to use, E.g. "Standard_D2s_v3"
#   6/ admin_username               Windows local admin username
#   7/ admin_password               Windows local admin password
#   8/ powershell_script            Powershell script filename
#
# outputs.tf:
#   - resource_group_name
#   - virtual_network_name
#   - subnet_name
#   - public_ips
#   - private_ips
#   - azurerm_windows_virtual_machine"s
#
################################################################################

###
# Resource Group
###
resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = "${var.common_prefix}-rg"
}

###
# vNet
###
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.common_prefix}-vnet"
  address_space       = ["172.16.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  depends_on          = [azurerm_resource_group.rg]
}

###
# Subnet
###
resource "azurerm_subnet" "subnet" {

  name                 = "${var.common_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["172.16.1.0/24"]
  depends_on           =  [azurerm_virtual_network.vnet]
}

###
# Public IP"s
###
resource "azurerm_public_ip" "publicip" {
  count               = "${var.num_vms}"
  name                = "${var.common_prefix}-pip${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
  depends_on           = [azurerm_subnet.subnet]
}

###
# Network Security Group
###
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.common_prefix}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  depends_on           = [azurerm_subnet.subnet]

  security_rule {
    name                       = "AllowKMAcsHomeSSHAccess"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "98.193.213.172/32"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowKMAcsHomeHTTPAccess"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "98.193.213.172/32"
    destination_address_prefix = "*"
  }
   security_rule {
    name                       = "AllowKMAcsHomeHTTPSAccess"
    priority                   = 1020
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "98.193.213.172/32"
    destination_address_prefix = "*"
  }
 security_rule {
    name                       = "AllowKMAcsHomeRDPAccess"
    priority                   = 1030
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "98.193.213.172/32"
    destination_address_prefix = "*"
  }
}

###
# Private NICs
###
resource "azurerm_network_interface" "nic" {
  count               = "${var.num_vms}"
  name                = "${var.common_prefix}-nic${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  depends_on          = [azurerm_subnet.subnet]

  ip_configuration {
    name                          = "${var.common_prefix}-niccfg-${count.index}"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = "${element(azurerm_public_ip.publicip.*.id, count.index )}"
  }
}

###
# NIC Association (NIC -> NSG)
###
resource "azurerm_network_interface_security_group_association" "nic-nsg-assn" {
  count                     = "${var.num_vms}"
  network_interface_id      = "${azurerm_network_interface.nic.*.id[count.index]}"
  network_security_group_id = azurerm_network_security_group.nsg.id
  depends_on                 = [azurerm_subnet.subnet]
}

###
# vNet Peering for ANQ access
###

resource "azurerm_virtual_network_peering" "wrks2anq-peer" {
  name                      = "wrks2anq-peer"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = "/subscriptions/2f0fe240-4ebb-45eb-8307-9f54ae213157/resourceGroups/crucible/providers/Microsoft.Network/virtualNetworks/anq-net"
  depends_on                 = [azurerm_subnet.subnet]

}

resource "azurerm_virtual_network_peering" "anq2wrks-peer" {
  name                      = "anq2wrks-peer"
  resource_group_name       = "crucible"
  virtual_network_name      = "anq-net"
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
  depends_on                 = [azurerm_subnet.subnet]

}

###
# Worker VM"s
###
resource "azurerm_windows_virtual_machine" "vm" {
  count                 = "${var.num_vms}"
  name                  = "${var.common_prefix}-${count.index}"
  admin_username        = "${var.admin_username}" 
  admin_password        = "${var.admin_password}" 
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = ["${azurerm_network_interface.nic.*.id[count.index]}"]
  size                  = "${var.vmsize}" 
  timezone              = "Central Standard Time"
  priority		= "Spot"
  eviction_policy	= "Delete"
  zone                  = 1
  source_image_id       = "${var.os_image_id}" 
  depends_on             = [azurerm_virtual_network_peering.wrks2anq-peer,azurerm_virtual_network_peering.anq2wrks-peer]

  os_disk {
    name                 = "${var.common_prefix}-osdisk${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

###
# Disable the firewall on worker hosts
###
# resource "azurerm_virtual_machine_extension" "disablefirewall" {
#      count                = "${var.num_vms}"
#      name                 = "${var.common_prefix}-fw-${count.index}"
#      virtual_machine_id   = "${element(azurerm_windows_virtual_machine.vm.*.id, count.index )}"
#      publisher            = "Microsoft.Compute"
#      type                 = "CustomScriptExtension"
#      type_handler_version = "1.10"
#      depends_on            = [azurerm_windows_virtual_machine.vm]
# 
#      protected_settings = <<PROT
#      {
#          "script": "${base64encode(file(var.powershell_script))}"
#      }
#      PROT
#  }

################################################################################
# Maestro Server, Public & Private IP"s, Association, VM
################################################################################

resource "azurerm_public_ip" "maestro_publicip" {
  name                = "${var.common_prefix}-maestro-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
  depends_on          = [azurerm_subnet.subnet]
}

resource "azurerm_network_interface" "maestro_nic" {
  name                = "${var.common_prefix}-maestro-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  depends_on          = [azurerm_subnet.subnet]

  ip_configuration {
    name                          = "${var.common_prefix}-maestro-niccfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.maestro_publicip.id
  }
}

resource "azurerm_network_interface_security_group_association" "maestro-nic-nsg-assn" {
  network_interface_id      = azurerm_network_interface.maestro_nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
  depends_on                = [azurerm_subnet.subnet]
}

###
# Maestro VM
###
resource "azurerm_windows_virtual_machine" "maestro_vm" {
  name                  = "${var.common_prefix}-maestro"
  computer_name         = "Maestro"
  admin_username        = "${var.admin_username}" 
  admin_password        = "${var.admin_password}" 
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.maestro_nic.id]
  size                  = "${var.vmsize}" 
  timezone              = "Central Standard Time"
  zone                  = 1
  source_image_id       = "${var.os_image_id}" 
  depends_on             = [azurerm_virtual_network_peering.wrks2anq-peer,azurerm_virtual_network_peering.anq2wrks-peer]

  os_disk {
    name                 = "${var.common_prefix}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

