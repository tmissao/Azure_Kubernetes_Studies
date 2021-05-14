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
    min_count = 2
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

  role_based_access_control {
    enabled = true
  }

  tags = var.tags
}

# Allows Kubernetes to Pull ACR images
resource "azurerm_role_assignment" "aks-acr" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# Creates An Identity to Pod
resource "azurerm_user_assigned_identity" "aks_pod_identity_queue_contributor" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "queuecontributoraksidentity"
}

# Allows Kubernetes to Manage Identity Created on AKS Nodes
resource "azurerm_role_assignment" "aks_identity_operator" {
  scope                = azurerm_user_assigned_identity.aks_pod_identity_queue_contributor.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# Allows Kubernetes to Manage VMs on AKS Nodes
resource "azurerm_role_assignment" "aks_vm_contributor" {
  scope = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourcegroups/${azurerm_kubernetes_cluster.aks.node_resource_group}"
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

resource "azurerm_role_assignment" "aks-q1" {
  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Storage/storageAccounts/${azurerm_storage_account.storage.name}/queueServices/default/queues/queue-1"
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_pod_identity_queue_contributor.principal_id 
}

output "aad_pod_identity_resource_id" {
  value       = azurerm_user_assigned_identity.aks_pod_identity_queue_contributor.id
  description = "Resource ID for the Managed Identity for AAD Pod Identity"
}

output "aad_pod_identity_client_id" {
  value       = azurerm_user_assigned_identity.aks_pod_identity_queue_contributor.client_id
  description = "Client ID for the Managed Identity for AAD Pod Identity"
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