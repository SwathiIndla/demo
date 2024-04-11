terraform {
  backend "azurerm" {
   storage_account_name = "sgeaccountname"
   container_name      = "swaswekav"
   key                  = "terraform.tfstate"
   resource_group_name = "demo-rm"
}
} 
