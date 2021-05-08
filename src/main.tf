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
}

resource "azurerm_kubernetes_cluster" "aks" {
  name = var.project_name
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix = var.project_name

  default_node_pool {
    name = "default"
    enable_auto_scaling = true
    max_count = 2
    node_count = 2
    min_count = 1
    vm_size = "Standard_B2ms"
    node_labels = { "node-type" = "system" }
    vnet_subnet_id = azurerm_subnet.subnets["backend"].id
    tags = var.tags
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    load_balancer_sku = "standard"
    service_cidr = var.vnet_kubernets-services_address_space
    dns_service_ip = cidrhost(var.vnet_kubernets-services_address_space, 10)
    docker_bridge_cidr = "172.17.0.1/16"
  }

  identity {
    type = "SystemAssigned"
  }

  addon_profile {
    aci_connector_linux {
      enabled = false
    }

    azure_policy {
      enabled = false
    }

    http_application_routing {
      enabled = false
    }

    kube_dashboard {
      enabled = false
    }

    oms_agent {
      enabled = false
    }
  }

  tags = var.tags
}

# resource "azurerm_kubernetes_cluster_node_pool" "spot-workers" {
#   name                  = "spot"
#   kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
#   vm_size               = "Standard_B1S"
#   enable_auto_scaling   = true
#   node_count            = 1
#   max_count = 5
#   min_count = 1
#   # priority = "Spot"
#   # spot_max_price = -1
#   # eviction_policy = "Delete"
#   availability_zones = [1,2,3]
#   node_labels = { 
#     "node-type" = "worker"
#   }
#   # node_taints = [
#   #   "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
#   # ]
#   vnet_subnet_id = azurerm_subnet.subnets["backend"].id
#   tags = var.tags
# }
