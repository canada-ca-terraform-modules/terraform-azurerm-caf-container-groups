# Terraform tests for terraform-azurerm-caf-container-groups
# Uses mock providers — no Azure credentials required.
# Run with: terraform test

mock_provider "azurerm" {}
mock_provider "null" {}

# ---------------------------------------------------------------------------
# Shared variable defaults re-used across runs
# ---------------------------------------------------------------------------
variables {
  env               = "DEV"
  userDefinedString = "pipelineAgent"
  location          = "canadacentral"
  tags              = {}
  extra_env_vars    = {}
  resource_groups   = {}
  subnets           = {}

  container_group = {
    resource_group = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/Management"
    os_type        = "Linux"
    subnet         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net-rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/OZ"

    dns_config = {
      nameservers = ["172.16.16.132", "172.16.16.133"]
    }

    image_registry_credentials = {
      server   = "devopspipeline.azurecr.io"
      username = "devopspipeline"
      password = "secret"
    }

    container = [
      {
        name                  = "pipelineagent1"
        image                 = "devopspipeline.azurecr.io/pipeline-agent:3.0"
        cpu                   = 1
        memory                = 1.5
        port                  = 80
        protocol              = "TCP"
        environment_variables = { "AZP_URL" = "https://dev.azure.com/Azure163g3-CloudOperations" }
      }
    ]
  }
}

# ---------------------------------------------------------------------------
# Run 1: Naming convention
# ---------------------------------------------------------------------------
run "naming_convention" {
  command = plan

  assert {
    condition     = azurerm_container_group.container_group.name == "DEVSLD-pipelineAgent-ci"
    error_message = "Container group name does not match naming convention: expected DEVSLD-pipelineAgent-ci"
  }
}

# ---------------------------------------------------------------------------
# Run 2: Defaults (ip_address_type, sku, restart_policy)
# ---------------------------------------------------------------------------
run "default_values" {
  command = plan

  assert {
    condition     = azurerm_container_group.container_group.ip_address_type == "Private"
    error_message = "Default ip_address_type should be Private"
  }

  assert {
    condition     = azurerm_container_group.container_group.sku == "Standard"
    error_message = "Default sku should be Standard"
  }

  assert {
    condition     = azurerm_container_group.container_group.restart_policy == "Always"
    error_message = "Default restart_policy should be Always"
  }
}

# ---------------------------------------------------------------------------
# Run 3: Single image_registry_credential (existing object format — backward compat)
# ---------------------------------------------------------------------------
run "single_registry_credential" {
  command = plan

  assert {
    condition     = length(azurerm_container_group.container_group.image_registry_credential) == 1
    error_message = "Single object credential format should produce exactly 1 image_registry_credential block"
  }
}

# ---------------------------------------------------------------------------
# Run 4: Multiple registry credentials (new list format)
# ---------------------------------------------------------------------------
run "multi_registry_credentials" {
  command = plan

  variables {
    container_group = {
      resource_group = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/prod-rg"
      os_type        = "Linux"
      subnet         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net-rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/app"

      image_registry_credentials = [
        { server = "registry1.azurecr.io", username = "user1", password = "pass1" },
        { server = "registry2.azurecr.io", username = "user2", password = "pass2" },
      ]

      container = [
        {
          name   = "app"
          image  = "registry1.azurecr.io/app:latest"
          cpu    = 2
          memory = 4
          port   = 443
        }
      ]
    }
  }

  assert {
    condition     = length(azurerm_container_group.container_group.image_registry_credential) == 2
    error_message = "List format should produce 2 image_registry_credential blocks"
  }
}

# ---------------------------------------------------------------------------
# Run 5: Spot priority — no subnet, ip_address_type = None
# ---------------------------------------------------------------------------
run "spot_priority_no_subnet" {
  command = plan

  variables {
    container_group = {
      resource_group  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dev-rg"
      os_type         = "Linux"
      ip_address_type = "None"
      priority        = "Spot"

      container = [
        {
          name   = "worker"
          image  = "mcr.microsoft.com/azure-cli:latest"
          cpu    = 1
          memory = 1
        }
      ]
    }
  }

  assert {
    condition     = azurerm_container_group.container_group.priority == "Spot"
    error_message = "Priority should be Spot"
  }

  assert {
    condition     = azurerm_container_group.container_group.subnet_ids == null
    error_message = "subnet_ids should be null when ip_address_type is None"
  }
}

# ---------------------------------------------------------------------------
# Run 6: Multi-port container (new ports list format)
# ---------------------------------------------------------------------------
run "multi_port_container" {
  command = plan

  variables {
    userDefinedString = "webserver"
    container_group = {
      resource_group = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dev-rg"
      os_type        = "Linux"
      subnet         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net-rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/web"

      container = [
        {
          name   = "nginx"
          image  = "nginx:latest"
          cpu    = 0.5
          memory = 0.5
          ports = [
            { port = 80, protocol = "TCP" },
            { port = 443, protocol = "TCP" },
          ]
        }
      ]
    }
  }

  assert {
    condition     = azurerm_container_group.container_group.name == "DEVSLD-webserver-ci"
    error_message = "Container group name should be DEVSLD-webserver-ci"
  }
}

# ---------------------------------------------------------------------------
# Run 7: Optional dns_config omitted (not required for non-ENT deployments)
# ---------------------------------------------------------------------------
run "no_dns_config" {
  command = plan

  variables {
    container_group = {
      resource_group = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dev-rg"
      os_type        = "Linux"
      subnet         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net-rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/OZ"

      image_registry_credentials = {
        server   = "devopspipeline.azurecr.io"
        username = "user"
        password = "pass"
      }

      container = [
        {
          name   = "agent"
          image  = "devopspipeline.azurecr.io/agent:latest"
          cpu    = 1
          memory = 1
        }
      ]
    }
  }

  # Plan should succeed — dns_config is optional
  assert {
    condition     = azurerm_container_group.container_group.name == "DEVSLD-pipelineAgent-ci"
    error_message = "Container group should plan successfully without dns_config"
  }
}

# ---------------------------------------------------------------------------
# Run 8: Legacy naming (group + project supplied — preserves existing resource names)
# ---------------------------------------------------------------------------
run "legacy_naming_group_project" {
  command = plan

  variables {
    group   = "CTO"
    project = "ESLZ"
    container_group = {
      resource_group = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/Management"
      os_type        = "Linux"
      subnet         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net-rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/OZ"

      container = [
        {
          name   = "agent"
          image  = "devopspipeline.azurecr.io/agent:latest"
          cpu    = 1
          memory = 1
        }
      ]
    }
  }

  assert {
    condition     = azurerm_container_group.container_group.name == "DEV-CTO-ESLZ-pipelineAgent"
    error_message = "Legacy naming must produce {env}-{group}-{project}-{userDefinedString} when group and project are supplied"
  }
}

# ---------------------------------------------------------------------------
# Run 9: Explicit name override via container_group.name
# ---------------------------------------------------------------------------
run "explicit_name_override" {
  command = plan

  variables {
    container_group = {
      name           = "GcDc-CTO-ESLZ-quicktest"
      resource_group = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/Management"
      os_type        = "Linux"
      subnet         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net-rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/OZ"

      container = [
        {
          name   = "agent"
          image  = "devopspipeline.azurecr.io/agent:latest"
          cpu    = 1
          memory = 1
        }
      ]
    }
  }

  assert {
    condition     = azurerm_container_group.container_group.name == "GcDc-CTO-ESLZ-quicktest"
    error_message = "container_group.name must override computed name when set"
  }
}

# ---------------------------------------------------------------------------
# Run 10: With diagnostics (Log Analytics)
# ---------------------------------------------------------------------------
run "with_diagnostics" {
  command = plan

  variables {
    container_group = {
      resource_group = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/Management"
      os_type        = "Linux"
      subnet         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net-rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/OZ"

      diagnostics = {
        log_analytics = {
          workspace_id  = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
          workspace_key = "base64encodedkeyhere=="
          log_type      = "ContainerInsights"
        }
      }

      dns_config = {
        nameservers = ["172.16.16.132"]
      }

      image_registry_credentials = {
        server   = "devopspipeline.azurecr.io"
        username = "user"
        password = "pass"
      }

      container = [
        {
          name   = "agent"
          image  = "devopspipeline.azurecr.io/agent:latest"
          cpu    = 1
          memory = 1
          port   = 80
        }
      ]
    }
  }

  assert {
    condition     = length(azurerm_container_group.container_group.diagnostics) == 1
    error_message = "diagnostics block should be set when diagnostics variable is provided"
  }
}

# ---------------------------------------------------------------------------
# Run 11: DNS label, reuse policy, and zones
# ---------------------------------------------------------------------------
run "dns_label_and_zones" {
  command = plan

  variables {
    container_group = {
      resource_group              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/Management"
      os_type                     = "Linux"
      ip_address_type             = "Public"
      dns_name_label              = "aci-pipeline-agent"
      dns_name_label_reuse_policy = "Noreuse"
      zones                       = ["1", "2"]

      container = [
        {
          name   = "agent"
          image  = "devopspipeline.azurecr.io/agent:latest"
          cpu    = 1
          memory = 1
          port   = 80
        }
      ]
    }
  }

  assert {
    condition     = azurerm_container_group.container_group.dns_name_label == "aci-pipeline-agent"
    error_message = "dns_name_label should be set when provided"
  }

  assert {
    condition     = azurerm_container_group.container_group.dns_name_label_reuse_policy == "Noreuse"
    error_message = "dns_name_label_reuse_policy should be set when provided"
  }

  assert {
    condition     = length(azurerm_container_group.container_group.zones) == 2
    error_message = "zones should contain all configured values"
  }
}

# ---------------------------------------------------------------------------
# Run 12: Identity and key vault CMK arguments
# ---------------------------------------------------------------------------
run "identity_and_cmk" {
  command = plan

  variables {
    container_group = {
      resource_group                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/Management"
      os_type                             = "Linux"
      subnet                              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net-rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/OZ"
      key_vault_key_id                    = "https://kv-demo.vault.azure.net/keys/key1/00000000000000000000000000000000"
      key_vault_user_assigned_identity_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/id-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/aci-id"

      identity = {
        type         = "UserAssigned"
        identity_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/id-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/aci-id"]
      }

      container = [
        {
          name   = "agent"
          image  = "devopspipeline.azurecr.io/agent:latest"
          cpu    = 1
          memory = 1
        }
      ]
    }
  }

  assert {
    condition     = azurerm_container_group.container_group.key_vault_key_id == "https://kv-demo.vault.azure.net/keys/key1/00000000000000000000000000000000"
    error_message = "key_vault_key_id should be set when provided"
  }

  assert {
    condition     = length(azurerm_container_group.container_group.identity) == 1
    error_message = "identity block should be present when identity is configured"
  }
}

# ---------------------------------------------------------------------------
# Run 13: Exposed ports and init_container blocks
# ---------------------------------------------------------------------------
run "exposed_ports_and_init_container" {
  command = plan

  variables {
    container_group = {
      resource_group = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/Management"
      os_type        = "Linux"
      subnet         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net-rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/OZ"

      exposed_port = [
        { port = 80, protocol = "TCP" },
        { port = 443, protocol = "TCP" },
      ]

      init_container = [
        {
          name     = "init-app"
          image    = "busybox:latest"
          commands = ["/bin/sh", "-c", "echo init"]
          environment_variables = {
            INIT_ENV = "value"
          }
          secure_environment_variables = {
            INIT_SECRET = "secret"
          }
          volumes = [
            {
              name       = "git-volume"
              mount_path = "/init"
              git_repo = {
                url       = "https://example.com/repo.git"
                directory = "bootstrap"
              }
            }
          ]
          security = {
            privilege_enabled = true
          }
        }
      ]

      container = [
        {
          name   = "agent"
          image  = "devopspipeline.azurecr.io/agent:latest"
          cpu    = 1
          memory = 1
          port   = 80
        }
      ]
    }
  }

  assert {
    condition     = length(azurerm_container_group.container_group.exposed_port) == 2
    error_message = "exposed_port should render all configured ports"
  }

  assert {
    condition     = length(azurerm_container_group.container_group.init_container) == 1
    error_message = "init_container should render when configured"
  }
}

# ---------------------------------------------------------------------------
# Run 14: Container optional nested fields (probes, volume, limits, commands)
# ---------------------------------------------------------------------------
run "container_optional_fields" {
  command = plan

  variables {
    container_group = {
      resource_group = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/Management"
      os_type        = "Linux"
      subnet         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net-rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/OZ"

      container = [
        {
          name         = "agent"
          image        = "devopspipeline.azurecr.io/agent:latest"
          cpu          = 1
          memory       = 1
          cpu_limit    = 2
          memory_limit = 2
          commands     = ["/bin/sh", "-c", "echo run"]

          secure_environment_variables = {
            SECRET_VALUE = "abc"
          }

          volumes = [
            {
              name                 = "files"
              mount_path           = "/mnt/files"
              read_only            = false
              storage_account_name = "stacct"
              storage_account_key  = "key"
              share_name           = "share"
            }
          ]

          readiness_probe = {
            period_seconds = 10
            http_get = {
              path   = "/healthz"
              port   = 80
              scheme = "http"
            }
          }

          liveness_probe = {
            period_seconds = 15
            exec           = ["/bin/sh", "-c", "test -f /tmp/live"]
          }

          security = {
            privilege_enabled = true
          }
        }
      ]
    }
  }

  assert {
    condition     = length(azurerm_container_group.container_group.container) == 1
    error_message = "container block should be present"
  }

  assert {
    condition     = length(azurerm_container_group.container_group.container[0].readiness_probe) == 1
    error_message = "readiness_probe should be present when configured"
  }

  assert {
    condition     = length(azurerm_container_group.container_group.container[0].liveness_probe) == 1
    error_message = "liveness_probe should be present when configured"
  }
}

# ---------------------------------------------------------------------------
# Run 15: stop_containers enables null_resource helper
# NOTE: this only asserts the resource is created with count = 1. The actual
# provisioner body runs an `az container stop` local-exec against real Azure
# subscriptions (see stop_container_probe_subscriptions in variable.tf) and
# cannot be meaningfully exercised under mock_provider/terraform test -- there
# is no equivalent of a live subscription/CLI to assert against here.
# ---------------------------------------------------------------------------
run "stop_containers_helper" {
  command = plan

  variables {
    container_group = {
      resource_group  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/Management"
      os_type         = "Linux"
      subnet          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net-rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/OZ"
      stop_containers = true

      container = [
        {
          name   = "agent"
          image  = "devopspipeline.azurecr.io/agent:latest"
          cpu    = 1
          memory = 1
        }
      ]
    }
  }

  assert {
    condition     = length(null_resource.local-exec-stop) == 1
    error_message = "stop_containers=true should create null_resource.local-exec-stop"
  }
}
