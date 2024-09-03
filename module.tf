resource "azurerm_container_group" "container_group" {
  name = local.container_group-name
  resource_group_name = local.resource_group_name
  location = var.location
  os_type = var.container_group.os_type
  sku = try(var.container_group.sku, "Standard")
  ip_address_type = try(var.container_group.ip_address_type, "Private")
  subnet_ids = [local.subnet_id]
  restart_policy = try(var.container_group.restart_policy, "Always")
  priority = try(var.container_group.priority, null)
  tags = merge(var.tags, try(var.container_group.tags, {}))

  dynamic "image_registry_credential" {
    for_each = try(var.container_group.image_registry_credentials, false) != false ? [1] : []
    content {
      server = var.container_group.image_registry_credentials.server
      username = var.container_group.image_registry_credentials.username
      password = var.container_group.image_registry_credentials.password
      # user_assigned_identity_id = "/subscriptions/a76af5cd-e42a-4ce1-af35-86a309543ed5/resourceGroups/G3Sc-CPMS_MMahdavian_Management-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/testIdentity"
    }
  }

  dns_config {
    nameservers = var.container_group.dns_config.nameservers
  }

  dynamic "container" {
    for_each = var.container_group.container
    content {
      name = container.value["name"]
      image = container.value["image"]
      cpu = container.value["cpu"]
      memory = container.value["memory"]
      cpu_limit = try(container.value["cpu_limit"], null)
      memory_limit = try(container.value["memory_limit"], null)
      commands = try(container.value["commands"], null)
      ports {
        port = container.value["port"]
        protocol = try(container.value["protocol"], "TCP")
      }
      environment_variables = merge(container.value["environment_variables"], var.extra_env_vars)
    }
  }

  dynamic "identity" {
    for_each = try(var.container_group.identity, null) != null ? [1] : []
    content {
      type = var.container_group.identity.type
      identity_ids = try(var.container_group.identity.identity_ids)
    }
  }
}

resource "null_resource" "local-exec-stop" {
  count = try(var.container_group.stop_containers, false) ? 1 : 0

  depends_on = [ azurerm_container_group.container_group ]

  provisioner "local-exec" {
    command = "az container stop -n ${local.container_group-name}  -g ${local.resource_group_name}"
  }
}