# Upgrade compatibility test for azurerm_container_group.
# State is shared between runs: apply establishes baseline state, then plan verifies
# additive upgrade inputs do not alter naming/address behavior.

mock_provider "azurerm" {}
mock_provider "null" {}

variables {
  env               = "DEV"
  userDefinedString = "pipelineAgent"
  location          = "canadacentral"
  tags              = {}
  extra_env_vars    = {}
  resource_groups   = {}
  subnets           = {}
}

run "baseline_apply" {
  command = apply

  variables {
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
          port   = 80
        }
      ]
    }
  }

  assert {
    condition     = azurerm_container_group.container_group.name == "DEVSLD-pipelineAgent-ci"
    error_message = "Baseline apply should keep expected container group name"
  }
}

run "upgrade_plan_no_replacement" {
  command = plan

  variables {
    container_group = {
      resource_group              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/Management"
      os_type                     = "Linux"
      ip_address_type             = "Public"
      dns_name_label              = "aci-pipeline-agent"
      dns_name_label_reuse_policy = "Noreuse"
      zones                       = ["1"]
      container = [
        {
          name   = "agent"
          image  = "devopspipeline.azurecr.io/agent:latest"
          cpu    = 1
          memory = 1
          ports  = [{ port = 80, protocol = "TCP" }]
        }
      ]
    }
  }

  assert {
    condition     = azurerm_container_group.container_group.name == "DEVSLD-pipelineAgent-ci"
    error_message = "Upgrade plan should preserve container group name"
  }

  assert {
    condition     = azurerm_container_group.container_group.dns_name_label == "aci-pipeline-agent"
    error_message = "Upgrade plan should apply additive dns_name_label setting"
  }
}
