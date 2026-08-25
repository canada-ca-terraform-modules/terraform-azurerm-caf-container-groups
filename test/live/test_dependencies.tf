# test_dependencies.tf
# Self-contained dependency resources, owned entirely by this harness.
#
# Deliberately NOT reusing any shared/production resource group, vnet, or
# subnet: writing into a shared/L1-managed resource usually requires
# elevated, L1-scoped permissions. A dedicated throwaway RG + vnet + subnet
# here needs only Contributor on the sandbox subscription and can never
# collide with or affect any production resource.
#
# The subnet needs a delegation to Microsoft.ContainerInstance/containerGroups -
# azurerm_container_group with ip_address_type = "Private" (this module's
# default) requires the target subnet to have that delegation or the resource
# creation is rejected by Azure.

resource "azurerm_resource_group" "live_test" {
  # PR-number suffix keeps two concurrently open PRs against this module from
  # colliding on the same sandbox resource group.
  name     = "${var.env}-caf-container-groups-live-test-${var.pr_number}-rg"
  location = var.location

  # pr-number tag (ticket 13): lets the nightly orphan sweeper find this RG
  # by tag and match it back to a PR, independent of naming convention.
  tags = {
    "pr-number" = var.pr_number
  }
}

resource "azurerm_virtual_network" "live_test" {
  name                = "${var.env}-caf-container-groups-live-test-${var.pr_number}-vnet"
  address_space       = ["10.251.0.0/16"] # arbitrary, unpeered - collision-safe by construction
  location            = azurerm_resource_group.live_test.location
  resource_group_name = azurerm_resource_group.live_test.name
}

resource "azurerm_subnet" "live_test" {
  name                 = "${var.env}-caf-container-groups-live-test-${var.pr_number}-snet"
  resource_group_name  = azurerm_resource_group.live_test.name
  virtual_network_name = azurerm_virtual_network.live_test.name
  address_prefixes     = ["10.251.1.0/24"]

  delegation {
    name = "aci-delegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

locals {
  # terraform-azurerm-caf-container-groups expects purpose-keyed maps for
  # both resource_groups and subnets.
  resource_groups = { live_test = { name = azurerm_resource_group.live_test.name } }
  subnets         = { live_test = { id = azurerm_subnet.live_test.id } }
}
