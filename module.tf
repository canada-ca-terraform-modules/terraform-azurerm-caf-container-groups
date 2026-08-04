resource "azurerm_container_group" "container_group" {
  name                = local.container_group-name
  resource_group_name = local.resource_group_name
  location            = var.location
  os_type             = var.container_group.os_type
  sku                 = try(var.container_group.sku, "Standard")
  ip_address_type     = try(var.container_group.ip_address_type, "Private")
  subnet_ids          = local.subnet_id != null ? [local.subnet_id] : null
  restart_policy      = try(var.container_group.restart_policy, "Always")
  priority            = try(var.container_group.priority, null)
  tags                = merge(var.tags, try(var.container_group.tags, {}))

  dns_name_label                      = try(var.container_group.dns_name_label, null)
  dns_name_label_reuse_policy         = try(var.container_group.dns_name_label_reuse_policy, null)
  key_vault_key_id                    = try(var.container_group.key_vault_key_id, null)
  key_vault_user_assigned_identity_id = try(var.container_group.key_vault_user_assigned_identity_id, null)
  zones                               = try(var.container_group.zones, null)

  dynamic "image_registry_credential" {
    for_each = local.image_registry_credentials
    content {
      server                    = image_registry_credential.value.server
      username                  = try(image_registry_credential.value.username, null)
      password                  = try(image_registry_credential.value.password, null)
      user_assigned_identity_id = try(image_registry_credential.value.user_assigned_identity_id, null)
    }
  }

  dynamic "dns_config" {
    for_each = try(var.container_group.dns_config, null) != null ? [1] : []
    content {
      nameservers    = var.container_group.dns_config.nameservers
      search_domains = try(var.container_group.dns_config.search_domains, null)
      options        = try(var.container_group.dns_config.options, null)
    }
  }

  dynamic "diagnostics" {
    for_each = try(var.container_group.diagnostics, null) != null ? [1] : []
    content {
      log_analytics {
        log_type      = try(var.container_group.diagnostics.log_analytics.log_type, null)
        workspace_id  = var.container_group.diagnostics.log_analytics.workspace_id
        workspace_key = var.container_group.diagnostics.log_analytics.workspace_key
        metadata      = try(var.container_group.diagnostics.log_analytics.metadata, null)
      }
    }
  }

  dynamic "exposed_port" {
    for_each = try(var.container_group.exposed_port, [])
    content {
      port     = try(exposed_port.value["port"], null)
      protocol = try(exposed_port.value["protocol"], "TCP")
    }
  }

  dynamic "init_container" {
    for_each = try(var.container_group.init_container, [])
    content {
      name                         = init_container.value["name"]
      image                        = init_container.value["image"]
      environment_variables        = try(init_container.value["environment_variables"], {})
      secure_environment_variables = try(init_container.value["secure_environment_variables"], {})
      commands                     = try(init_container.value["commands"], null)

      dynamic "volume" {
        for_each = try(init_container.value["volumes"], [])
        content {
          name                 = volume.value["name"]
          mount_path           = volume.value["mount_path"]
          read_only            = try(volume.value["read_only"], false)
          empty_dir            = try(volume.value["empty_dir"], null)
          storage_account_name = try(volume.value["storage_account_name"], null)
          storage_account_key  = try(volume.value["storage_account_key"], null)
          share_name           = try(volume.value["share_name"], null)
          secret               = try(volume.value["secret"], null)

          dynamic "git_repo" {
            for_each = try(volume.value["git_repo"], null) != null ? [1] : []
            content {
              url       = volume.value["git_repo"].url
              directory = try(volume.value["git_repo"].directory, null)
              revision  = try(volume.value["git_repo"].revision, null)
            }
          }
        }
      }

      dynamic "security" {
        for_each = try(init_container.value["security"], null) != null ? [1] : []
        content {
          privilege_enabled = init_container.value["security"].privilege_enabled
        }
      }
    }
  }

  dynamic "container" {
    for_each = var.container_group.container
    content {
      name                         = container.value["name"]
      image                        = container.value["image"]
      cpu                          = container.value["cpu"]
      memory                       = container.value["memory"]
      cpu_limit                    = try(container.value["cpu_limit"], null)
      memory_limit                 = try(container.value["memory_limit"], null)
      commands                     = try(container.value["commands"], null)
      environment_variables        = merge(try(container.value["environment_variables"], {}), var.extra_env_vars)
      secure_environment_variables = try(container.value["secure_environment_variables"], {})

      # Supports both old single-port format (port/protocol keys) and new list format (ports = [{...}])
      dynamic "ports" {
        for_each = try(
          container.value["ports"],
          try(container.value["port"], null) != null ? [{ port = container.value["port"], protocol = try(container.value["protocol"], "TCP") }] : []
        )
        content {
          port     = ports.value["port"]
          protocol = try(ports.value["protocol"], "TCP")
        }
      }

      dynamic "volume" {
        for_each = try(container.value["volumes"], [])
        content {
          name                 = volume.value["name"]
          mount_path           = volume.value["mount_path"]
          read_only            = try(volume.value["read_only"], false)
          empty_dir            = try(volume.value["empty_dir"], null)
          storage_account_name = try(volume.value["storage_account_name"], null)
          storage_account_key  = try(volume.value["storage_account_key"], null)
          share_name           = try(volume.value["share_name"], null)
          secret               = try(volume.value["secret"], null)

          dynamic "git_repo" {
            for_each = try(volume.value["git_repo"], null) != null ? [1] : []
            content {
              url       = volume.value["git_repo"].url
              directory = try(volume.value["git_repo"].directory, null)
              revision  = try(volume.value["git_repo"].revision, null)
            }
          }
        }
      }

      dynamic "readiness_probe" {
        for_each = try(container.value["readiness_probe"], null) != null ? [1] : []
        content {
          exec                  = try(container.value["readiness_probe"].exec, null)
          initial_delay_seconds = try(container.value["readiness_probe"].initial_delay_seconds, null)
          period_seconds        = try(container.value["readiness_probe"].period_seconds, null)
          failure_threshold     = try(container.value["readiness_probe"].failure_threshold, null)
          success_threshold     = try(container.value["readiness_probe"].success_threshold, null)
          timeout_seconds       = try(container.value["readiness_probe"].timeout_seconds, null)

          dynamic "http_get" {
            for_each = try(container.value["readiness_probe"].http_get, null) != null ? [1] : []
            content {
              path         = try(container.value["readiness_probe"].http_get.path, null)
              port         = try(container.value["readiness_probe"].http_get.port, null)
              scheme       = try(container.value["readiness_probe"].http_get.scheme, null)
              http_headers = try(container.value["readiness_probe"].http_get.http_headers, null)
            }
          }
        }
      }

      dynamic "liveness_probe" {
        for_each = try(container.value["liveness_probe"], null) != null ? [1] : []
        content {
          exec                  = try(container.value["liveness_probe"].exec, null)
          initial_delay_seconds = try(container.value["liveness_probe"].initial_delay_seconds, null)
          period_seconds        = try(container.value["liveness_probe"].period_seconds, null)
          failure_threshold     = try(container.value["liveness_probe"].failure_threshold, null)
          success_threshold     = try(container.value["liveness_probe"].success_threshold, null)
          timeout_seconds       = try(container.value["liveness_probe"].timeout_seconds, null)

          dynamic "http_get" {
            for_each = try(container.value["liveness_probe"].http_get, null) != null ? [1] : []
            content {
              path         = try(container.value["liveness_probe"].http_get.path, null)
              port         = try(container.value["liveness_probe"].http_get.port, null)
              scheme       = try(container.value["liveness_probe"].http_get.scheme, null)
              http_headers = try(container.value["liveness_probe"].http_get.http_headers, null)
            }
          }
        }
      }

      dynamic "security" {
        for_each = try(container.value["security"], null) != null ? [1] : []
        content {
          privilege_enabled = container.value["security"].privilege_enabled
        }
      }
    }
  }

  dynamic "identity" {
    for_each = try(var.container_group.identity, null) != null ? [1] : []
    content {
      type         = var.container_group.identity.type
      identity_ids = try(var.container_group.identity.identity_ids, [])
    }
  }

  # WARNING: azurerm_container_group's `container` block forces replacement on any change
  # (per provider docs, nearly every argument on this resource is ForceNew). This module
  # intentionally ignores drift on `container` so routine plans don't propose destroying and
  # recreating the group; apply container changes explicitly with:
  #   terragrunt apply -replace='module.containerGroups["<key>"].azurerm_container_group.container_group'
  # See README.md "Known Behavior" section and ESLZ/containerGroups.tfvars for the caller-facing note.
  lifecycle {
    ignore_changes = [container]
  }
}

resource "null_resource" "local-exec-stop" {
  count = try(var.container_group.stop_containers, false) ? 1 : 0

  depends_on = [azurerm_container_group.container_group]

  provisioner "local-exec" {
    command     = <<-EOT
      subs="${join(" ", var.stop_container_probe_subscriptions)} $ARM_SUBSCRIPTION_ID"

      for SUB in $subs
      do
        resource=$(az resource list --subscription $SUB --query "[?name=='${local.container_group-name}']" -o tsv)

        if [ ! -z "$resource" ]; then
          az container stop -n ${local.container_group-name} -g ${local.resource_group_name} --subscription $SUB
          break
        fi
      done
    EOT
    interpreter = ["/bin/bash", "-c"]
  }

  lifecycle {
    replace_triggered_by = [azurerm_container_group.container_group]
  }
}
