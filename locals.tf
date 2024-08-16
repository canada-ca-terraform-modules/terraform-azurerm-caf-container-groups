locals {
  resource_group_name = strcontains(var.container_group.resource_group, "/resourceGroups/") ? regex("[^\\/]+$", var.container_group.resource_group) :  var.resource_groups[var.container_group.resource_group].name
  subnet_id = strcontains(var.container_group.subnet, "/resourceGroups/") ? var.container_group.subnet : var.subnets[var.container_group.subnet].id
}