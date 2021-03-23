provider "azurerm" {
  version = "=2.0.0"
  features {}
}

#######################################################################
## Create Resource Group
#######################################################################

resource "azurerm_resource_group" "hub-spoke-microhack-rg" {
  name     = "hub-spoke-microhack-rg"
  location = var.location

  tags = {
    environment = "hub-spoke"
    deployment  = "terraform"
    microhack   = "hub-spoke"
  }
}