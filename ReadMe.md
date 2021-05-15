# Azure Kubernetes Studies

This project intends to summarize all the knowledge earned during my studies of Azure Kubernetes Service (AKS) and also Kubernetes itself.

The content could be divided into two sections:

- Azure
- Kubernetes

## Azure
---

All resources in the azure environment was built using terraform, and the main purpose was understand how create several common resources such as: 

- `Storage Account`
- `Storage Account Containers`
- `Storage Account Queues`
- `Vnet and Subnets`
- `Virtual Machines`
- `Azure Container Registry`
- `Azure Kubernetes Services`
- `User Manager Identities`
- `Role Assignment`

Also, all development explored how to safe authenticate with azure using services like `Azure Authenticator` (sdk), `Identities`, `Roles` and `RBAC`.

## Kubernetes
---

On this section was studied the main operations and configuration on kubernets like:

- [`Ingress Gateway (Nginx)`](./artifacts/deployments/nginx-ingress-gateway)

- [`Ingress Gateway HTTPS (Nginx + CertManager)`](./artifacts/deployments/nginx-ingress-gateway-ssl)

- [`Service Mesh (Istio)`](./artifacts/deployments/istio)

- [`Extracting Logs (Fluentbit)`](./artifacts/deployments/fluentbit)

- [`Cluster Monitoring (Prometheus Stack)`](./artifacts/deployments/prometheus)

- [`Integrating Cluster Monitoring and Service Mesh Monitoring (Prometheus Stack + Istio)`](./artifacts/deployments/prometheus-istio)

- [` Pod Identity (Kubernetes + Azure Active Directory)`](./artifacts/deployments/aad-pod-identity)