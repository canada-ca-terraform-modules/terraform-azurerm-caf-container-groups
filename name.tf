locals {
  container_group-regex                                = "/[^0-9a-z]/" # Anti-pattern to match all characters not in: 0-9 a-z
  env-regex_compliant_4                                = replace(var.env, local.container_group-regex, "")
  container_group-userDefinedString-regex_compliant_16 = replace(var.userDefinedString, local.container_group-regex, "")
  group-regex_compliant                                = replace(var.group, local.container_group-regex, "")
  project-regex_compliant                              = replace(var.project, local.container_group-regex, "")
  container_prefix                                     = "${local.env-regex_compliant_4}-${local.group-regex_compliant}-${local.project-regex_compliant}"
  # container_group-name                                 = substr("${local.container_prefix}${local.container_group-userDefinedString-regex_compliant_16}", 0, 24)
  container_group-name                                 = "${var.env}-${var.group}-${var.project}-${var.userDefinedString}"
}
