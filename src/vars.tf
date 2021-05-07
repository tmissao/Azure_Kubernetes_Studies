variable "project_name" { default = "missao-studies" }
variable "location" { default = "East US" }
variable "vnet_address_space" { default = ["10.0.0.0/16"] }
variable "vnet_subnets" { 
  default = {
    "backend": {
      address: ["10.0.1.0/24"]
    },
    "frontend": {
      address: ["10.0.100.0/24"]
    }
  }
}
variable "vnet_kubernets-services_address_space" { default = "10.0.20.0/24"}
variable "tags" {
  default = {
    "Terraform" = true
  }
 }