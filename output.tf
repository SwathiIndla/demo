output "resource_group_id" {
  value = azurerm_resource_group.demo-rm.id
}
output "continaer_name" {
  value = azurerm_storage_container.demo-con.name
}
