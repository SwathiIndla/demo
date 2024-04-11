provider "azurerm" {
  features { }
}

resource "azurerm_resource_group" "demo-rm" {
 name = "demo-rm"
 location = "eastus"  
}
resource "azurerm_storage_account" "demo-sca" {
  name                     = "sgeaccountname"
  resource_group_name      = "demo-rm"
  location                 = azurerm_resource_group.demo-rm.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
resource "azurerm_storage_container" "demo-con" {
  name                  = "swaswekav"
  storage_account_name  = azurerm_storage_account.demo-sca.name
  container_access_type = "private"
}
