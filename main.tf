provider "azurerm" {
  feature { }
}

resource "azure_resource_group" "demo-rm" {
 name = "demo-rm"
 location = "eastus"  
}
