# Azure Active Directory Pod identity for Kubernets

AAD Pod Identity enables Kubernetes applications to access cloud resources securely with Azure Active Directory using User-assigned managed identity and Service Principal.

## Setup
---

Before deploying the add-pod-identity it is necessary to fullfil the following requesites:

- `Allow AKS cluster to use RBAC`

AKS should be able to communicate with Azure, and also handle RBAC 

```bash
resource "azurerm_kubernetes_cluster" "aks" {
  # ...
  role_based_access_control {
    enabled = true
  }
  # ...
}
```
- `Allow AKS to pull images from ACR` - (optional) 

This example uses ACR images, so it is necessary to give permissions for AKS perform image pull requests. 

```bash
resource "azurerm_kubernetes_cluster" "aks" {
 # ...
}

resource "azurerm_container_registry" "acr" {
  # ...
}

resource "azurerm_role_assignment" "aks-acr" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}
```

- `Allow Kubernets to manage Nodes on AKS node pools`

```bash

data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "aks_vm_contributor" {
  scope = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourcegroups/${azurerm_kubernetes_cluster.aks.node_resource_group}"
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}
```

- `Deploy AAD Pod Identity`

```bash
# Adding AAD Pod Identity Repository
helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts

# Creates Namespace
kubectl create ns aad-identity

# Installing Pod Identity Repository
helm install aad-pod-identity aad-pod-identity/aad-pod-identity -n aad-identity
```

## Demo
---

Let's deploy a demo application on kubernetes which will produce messages to a queue

- `Creating the Storage Account and Queue`
```bash
resource "azurerm_storage_account" "storage" {
  name = var.storage_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier = "Standard"
  account_kind = "StorageV2"
  account_replication_type = "LRS"
  access_tier = "Hot"

  network_rules {
    default_action = "Deny"
    ip_rules = var.allowed_ips
    virtual_network_subnet_ids = [azurerm_subnet.subnets["backend"].id]
  }

  tags = var.tags
}

resource "azurerm_storage_queue" "queue1" {
  name                 = var.queue1_name
  storage_account_name = azurerm_storage_account.storage.name
}
```

- `Creating a Pod Identity and Allow Kubernets (AKS) Manage it`

The outputs will be used during deploy the application demo.

```bash
data "azurerm_subscription" "current" {}


resource "azurerm_user_assigned_identity" "aks_pod_identity_queue_contributor" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "queuecontributoraksidentity"
}

resource "azurerm_role_assignment" "aks_identity_operator" {
  scope                = azurerm_user_assigned_identity.aks_pod_identity_queue_contributor.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# It will be used to deploy the container
output "aad_pod_identity_resource_id" {
  value       = azurerm_user_assigned_identity.aks_pod_identity_queue_contributor.id
  description = "Resource ID for the Managed Identity for AAD Pod Identity"
}

# It will be used to deploy the container
output "aad_pod_identity_client_id" {
  value       = azurerm_user_assigned_identity.aks_pod_identity_queue_contributor.client_id
  description = "Client ID for the Managed Identity for AAD Pod Identity"
}
```

- `Adding Permissions on User Managed Identity created`
```bash
resource "azurerm_role_assignment" "aks-q1" {
  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Storage/storageAccounts/${azurerm_storage_account.storage.name}/queueServices/default/queues/queue-1"
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_pod_identity_queue_contributor.principal_id 
}
```

- `Deploy Application`
```yaml
# sender.yaml

apiVersion: "aadpodidentity.k8s.io/v1"
kind: AzureIdentity
metadata:
  name: my-identity # Identity Custom Name
spec:
  type: 0
  resourceID: ${IDENTITY_RESOURCE_ID} # <-- UserManaged Identity Resource ID created on Azure
  clientID: ${IDENTITY_CLIENT_ID} # <-- UserManaged Identity Client ID created on Azure
---
apiVersion: "aadpodidentity.k8s.io/v1"
kind: AzureIdentityBinding
metadata:
  name: my-identity-binding # AzureIdentityBinding Custom Name
spec:
  azureIdentity: my-identity # <-- AzureIdentity Name created K8's
  selector: my-identity # <-- AzureIdentity Name created K8's
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sender  
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sender
  template:
    metadata:
      labels:
        app: sender
        aadpodidbinding: my-identity # <-- AzureIdentity Name created K8's
    spec:
      containers:
      - name: sender
        image: missaoregistry.azurecr.io/studies/sender
```

- `Results`
After deploy, the application will start to send messages to queue, getting its authorization direct from Azure Active Directory.

```bash
kubectl logs sender-XXX-XXX

#Sent message successfully, service assigned message Id: 303293f7-1cc1-42dc-87d2-68fd299b2189, service assigned request Id: 46b464c5-5003-0082-06d8-489ed1000000

#Sent message successfully, service assigned message Id: 6731dc0f-ad38-4ef5-98da-76c1d3e345f1, service assigned request Id: 46b464d0-5003-0082-10d8-489ed1000000

#Sent message successfully, service assigned message Id: 39754ca0-a379-46d1-bdb3-543416f4897c, service assigned request Id: 46b464d7-5003-0082-17d8-489ed1000000

#Sent message successfully, service assigned message Id: 046593e0-cfc7-4030-8248-45ad2d75a608, service assigned request Id: 46b464dc-5003-0082-1bd8-489ed1000000

# ...
```

## References

- [`Azure Documentation`](https://azure.github.io/aad-pod-identity/docs/)

- [`Terraform Example`](https://gist.github.com/robinmanuelthiel/2b6ff87b5aa1e32e98bd1a9516ed2219)