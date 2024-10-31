variable "containerGroup" {
  type = any
  default = {}
}

module "containerGroups" {
  source = "github.com/canada-ca-terraform-modules/terraform-azurerm-caf-container-groups.git?ref=v1.0.4"
  for_each = var.containerGroup

  userDefinedString = each.key
  env = var.env 
  location = var.location
  container_group = each.value
  resource_groups = local.resource_groups_all
  subnets = local.subnets
  extra_env_vars = {"AZP_TOKEN" = var.token}
  tags = var.tags
}
