terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "RgProd" {
  name     = "RgProd${var.extension}"
  location = var.location
}

resource "azurerm_virtual_network" "vNetProd" {
  name                = "vNetProd"
  address_space       = [var.address_space]
  location            = azurerm_resource_group.RgProd.location
  resource_group_name = azurerm_resource_group.RgProd.name
}

resource "azurerm_subnet" "sNetProd" {
  name                 = "sNetProd"
  resource_group_name  = azurerm_resource_group.RgProd.name
  virtual_network_name = azurerm_virtual_network.vNetProd.name
  address_prefixes     = [var.subnet_prefix]
}

resource "azurerm_network_interface" "NIC" {
  count               = 2
  name                = "NIC${count.index}"
  location            = azurerm_resource_group.RgProd.location
  resource_group_name = azurerm_resource_group.RgProd.name

  ip_configuration {
    name                          = "IP"
    subnet_id                     = azurerm_subnet.sNetProd.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "VirtualMachine" {
  count               = 2
  name                = "VirtualMachine${count.index}"
  resource_group_name = azurerm_resource_group.RgProd.name
  location            = azurerm_resource_group.RgProd.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.NIC[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }
}
