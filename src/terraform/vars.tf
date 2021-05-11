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
variable "storage_allowed_ips" { default = ["179.153.195.58"] }
variable "tags" {
  default = {
    "Terraform" = true
  }
 }