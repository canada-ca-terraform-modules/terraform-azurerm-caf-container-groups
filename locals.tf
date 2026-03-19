locals {
  resource_group_name = strcontains(var.container_group.resource_group, "/resourceGroups/") ? regex("[^/]+$", var.container_group.resource_group) : var.resource_groups[var.container_group.resource_group].name

  # subnet_id is optional: not needed when ip_address_type is "None" (e.g. Spot priority)
  subnet_id = try(var.container_group.subnet, null) != null ? (
    strcontains(var.container_group.subnet, "/resourceGroups/") ? var.container_group.subnet : var.subnets[var.container_group.subnet].id
  ) : null

  # Normalize image_registry_credentials: accept either a single object {} or a list [{}]
  # Existing callers that pass a single object continue to work unchanged.
  _image_registry_credentials_raw = try(var.container_group.image_registry_credentials, [])
  # try() returns the first expression that evaluates without error:
  # - if a list was passed, tolist() succeeds and we use it directly
  # - if a single object was passed, tolist() errors, so we fall back to wrapping it in a list
  image_registry_credentials = try(
    tolist(local._image_registry_credentials_raw),
    [local._image_registry_credentials_raw]
  )
}
