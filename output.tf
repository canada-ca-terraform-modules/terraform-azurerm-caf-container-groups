output "container_group_name" {
  description = "Name of the container group"
  value = azurerm_container_group.container_group.name
}

output "container_group_id" {
  description = "ID of the container group"
  value = azurerm_container_group.container_group.id
}

output "container_group" {
  description = "Container group object"
  value = azurerm_container_group.container_group
}