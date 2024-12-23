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
      username = try(var.container_group.image_registry_credentials.username, null)
      password = try(var.container_group.image_registry_credentials.password, null)
      user_assigned_identity_id = try(var.container_group.image_registry_credentials.user_assigned_identity_id, null)
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
      identity_ids = try(var.container_group.identity.identity_ids, [])
    }
  }

  lifecycle {
    ignore_changes = [ container ]
  }
}

resource "null_resource" "local-exec-stop" {
  count = try(var.container_group.stop_containers, false) ? 1 : 0

  depends_on = [ azurerm_container_group.container_group ]

  provisioner "local-exec" {
    command = <<EOT
    subs="G3Mc-CTO-ENT-MRZ GcPc-CTO-ENT-CORE $ARM_SUBSCRIPTION_ID"

    for SUB in $subs
    do
      resource=$(az resource list --subscription $SUB --query "[?name=='${local.container_group-name}']" -o tsv)

      if [ ! -z "$resource" ]; then
        az container stop -n ${local.container_group-name}  -g ${local.resource_group_name} --subscription $SUB
        break
      fi
    done
    EOT
    interpreter = [ "/bin/bash", "-c" ]
  }

  lifecycle {
    replace_triggered_by = [ azurerm_container_group.container_group ]
  }
}
