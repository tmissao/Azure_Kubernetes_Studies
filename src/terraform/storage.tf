
resource "azurerm_storage_account" "storage" {
  name = "storagemissaoterraform"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier = "Standard"
  account_kind = "StorageV2"
  account_replication_type = "LRS"
  access_tier = "Hot"

  network_rules {
    default_action = "Deny"
    ip_rules = var.storage_allowed_ips
    virtual_network_subnet_ids = [azurerm_subnet.subnets["backend"].id]
  }

  tags = var.tags
}

resource "azurerm_storage_queue" "queue1" {
  name                 = "missao-queue-1"
  storage_account_name = azurerm_storage_account.storage.name
}

resource "azurerm_storage_queue" "queue2" {
  name                 = "missao-queue-2"
  storage_account_name = azurerm_storage_account.storage.name
}

resource "azurerm_storage_container" "container1" {
  name                  = "container-1"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "container2" {
  name                  = "container-2"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}