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
# Run 8: With diagnostics (Log Analytics)
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
