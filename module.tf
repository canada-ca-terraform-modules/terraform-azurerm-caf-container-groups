resource "azurerm_container_group" "container_group" {
  name = local.container_group-name
  resource_group_name = local.resource_group_name
  location = var.location
  os_type = var.container_group.os_type
  ip_address_type = try(var.container_group.ip_address_type, "Private")
  subnet_ids = [local.subnet_id]
  restart_policy = try(var.container_group.restart_policy, "Always")
  tags = merge(var.tags, try(var.container_group.tags, {}))

  dynamic "image_registry_credential" {
    for_each = try(var.container_group.image_registry_credentials, false) != false ? [1] : []
    content {
      server = var.container_group.image_registry_credentials.server
      username = var.container_group.image_registry_credentials.username
      password = var.container_group.image_registry_credentials.password
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
      ports {
        port = container.value["port"]
        protocol = try(container.value["protocol"], "TCP")
      }
      environment_variables = merge(container.value["environment_variables"], var.extra_env_vars)
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