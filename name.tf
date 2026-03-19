locals {
  # Explicit name override in container_group object takes highest priority.
  # Falls back to legacy naming when group+project are supplied (preserves existing resource names).
  # Falls back to new ESLZ convention when neither is present.
  container_group-name = try(
    var.container_group.name,
    var.group != null && var.project != null
    ? "${var.env}-${var.group}-${var.project}-${var.userDefinedString}"
    : "${var.env}SLD-${var.userDefinedString}-ci"
  )
}
