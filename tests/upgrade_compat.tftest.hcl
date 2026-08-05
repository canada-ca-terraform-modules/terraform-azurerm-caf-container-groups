# Upgrade compatibility test for azurerm_container_group.
# State is shared between runs: apply establishes baseline state, then plan verifies
# a genuinely additive upgrade input does not alter naming/address behavior or force
# replacement.
#
# NOTE: per the azurerm_container_group provider docs, nearly every top-level argument
# (ip_address_type, dns_name_label, dns_name_label_reuse_policy, zones, priority,
# restart_policy, dns_config, diagnostics, exposed_port, subnet_ids,
# image_registry_credential, key_vault_key_id, container, init_container, ...) is
# ForceNew -- changing any of them destroys and recreates the resource. Only `tags`
# (and `identity`) can change in place, so that's the only attribute exercised here as
# the "no replacement" case. The `id` stability assertion is what actually proves no
# replacement occurred: a forced replacement would leave `id` unknown at plan time and
# fail that condition, whereas a mere value-equality check on the changed attribute
# would pass either way.

mock_provider "azurerm" {}
mock_provider "null" {}

variables {
  env               = "DEV"
  userDefinedString = "pipelineAgent"
  location          = "canadacentral"
  extra_env_vars    = {}
  resource_groups   = {}
  subnets           = {}
}

run "baseline_apply" {
  command = apply

  variables {
    tags = {}
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
    tags = { environment = "upgrade-test" }
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
    error_message = "Upgrade plan should preserve container group name"
  }

  assert {
    condition     = azurerm_container_group.container_group.tags["environment"] == "upgrade-test"
    error_message = "Upgrade plan should apply additive tags change"
  }

  assert {
    condition     = azurerm_container_group.container_group.id == run.baseline_apply.container_group_id
    error_message = "id must remain stable across the upgrade plan -- if this fails, the changed input forces resource replacement"
  }
}
