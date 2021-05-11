resource "azurerm_resource_group" "rg" {
  name = var.project_name
  location = var.location
  tags = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name = "${var.project_name}-vnet"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space = var.vnet_address_space
  tags = var.tags
}

resource "azurerm_subnet" "subnets" {
  for_each = var.vnet_subnets
  name = "${var.project_name}-${each.key}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = each.value.address
  service_endpoints = each.value.services_endpoints
}