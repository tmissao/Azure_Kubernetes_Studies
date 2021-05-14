variable "project_name" { default = "missao-studies" }
variable "location" { default = "East US" }
variable "vnet_address_space" { default = ["10.0.0.0/16"] }
variable "vnet_subnets" { 
  default = {
    "backend": {
      address: ["10.0.1.0/24"]
      services_endpoints: ["Microsoft.Storage"]
    },
    "frontend": {
      address: ["10.0.100.0/24"]
      services_endpoints: []
    }
  }
}
variable "vnet_kubernets-services_address_space" { default = "10.0.20.0/24"}
variable "storage_name" { default = "storagemissaoterraform" }
variable "container1_name" { default = "container-1" }
variable "container2_name" { default = "container-2" }
variable "queue1_name" { default = "queue-1" }
variable "queue2_name" { default = "queue-2" }
variable "allowed_ips" { default = ["179.153.195.58", "187.183.123.142"] }
variable "container_registry_name" { default = "missaoregistry" }
variable "tags" {
  default = {
    "Terraform" = true
  }
 }