output "container_group_name" {
  description = "Name of the container group"
  value       = azurerm_container_group.container_group.name
}

output "container_group_id" {
  description = "ID of the container group"
  value       = azurerm_container_group.container_group.id
}

output "container_group" {
  description = "Container group object, excluding the deprecated network_profile_id attribute (referencing the whole resource surfaces a 'Deprecated value used' warning on every plan/apply/test - see README.md's Known Behavior section)"
  value = {
    id                                  = azurerm_container_group.container_group.id
    name                                = azurerm_container_group.container_group.name
    resource_group_name                 = azurerm_container_group.container_group.resource_group_name
    location                            = azurerm_container_group.container_group.location
    os_type                             = azurerm_container_group.container_group.os_type
    sku                                 = azurerm_container_group.container_group.sku
    ip_address_type                     = azurerm_container_group.container_group.ip_address_type
    ip_address                          = azurerm_container_group.container_group.ip_address
    fqdn                                = azurerm_container_group.container_group.fqdn
    subnet_ids                          = azurerm_container_group.container_group.subnet_ids
    restart_policy                      = azurerm_container_group.container_group.restart_policy
    priority                            = azurerm_container_group.container_group.priority
    tags                                = azurerm_container_group.container_group.tags
    dns_name_label                      = azurerm_container_group.container_group.dns_name_label
    dns_name_label_reuse_policy         = azurerm_container_group.container_group.dns_name_label_reuse_policy
    key_vault_key_id                    = azurerm_container_group.container_group.key_vault_key_id
    key_vault_user_assigned_identity_id = azurerm_container_group.container_group.key_vault_user_assigned_identity_id
    zones                               = azurerm_container_group.container_group.zones
    exposed_port                        = azurerm_container_group.container_group.exposed_port
    identity                            = azurerm_container_group.container_group.identity
    container                           = azurerm_container_group.container_group.container
    init_container                      = azurerm_container_group.container_group.init_container
    image_registry_credential           = azurerm_container_group.container_group.image_registry_credential
    dns_config                          = azurerm_container_group.container_group.dns_config
    diagnostics                         = azurerm_container_group.container_group.diagnostics
  }
  sensitive = true
}
