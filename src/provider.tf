terraform {
  backend "azurerm" {
    resource_group_name  = "terraform"
    storage_account_name = "missaoterraformstate"
    container_name       = "terraform-state"
    key                  = "state.tfstate"
  }
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.58.0"
    }
  }
}

provider "azurerm" {
  features {}
}