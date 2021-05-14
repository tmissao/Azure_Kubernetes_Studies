
resource "azurerm_container_registry" "acr" {
  name = var.container_registry_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  sku = "Basic"
  tags = var.tags
}

resource "null_resource" "build-acr-images" {
  provisioner "local-exec" {
    command = "/bin/bash ./scripts/build-images.sh"
    environment = {
      acr_registry     = azurerm_container_registry.acr.name
    }
  }
}