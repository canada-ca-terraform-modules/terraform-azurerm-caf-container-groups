variable "tags" {
  description = "Tags to be applied to the container group"
  type        = map(string)
  default     = {}
}

variable "userDefinedString" {
  description = "(Required) UserDefinedString part of the name of the container group"
  type        = string
}

variable "env" {
  description = "(Required) env value"
  type        = string
}

variable "group" {
  description = "(Optional) Group value — used to preserve legacy naming convention {env}-{group}-{project}-{userDefinedString}"
  type        = string
  default     = null
}

variable "project" {
  description = "(Optional) Project value — used to preserve legacy naming convention {env}-{group}-{project}-{userDefinedString}"
  type        = string
  default     = null
}

variable "location" {
  description = "(Required) Azure location where the container group will be placed"
  type        = string
  default     = "canadacentral"
}

variable "resource_groups" {
  description = "Resource group object containing all resource groups"
  type        = any
  default     = {}
}

variable "container_group" {
  description = "Object containing all container group parameters"
  type        = any
  default     = {}
}

variable "subnets" {
  description = "Object containing all subnets in the project"
  type        = any
  default     = {}
}

variable "extra_env_vars" {
  description = "Variables used in case it is easier to set a container environment variable as a variable in ESLZ"
  type        = any
  default     = {}
}

variable "stop_container_probe_subscriptions" {
  description = "(Optional) Subscription names/aliases that null_resource.local-exec-stop searches (in addition to the caller's active $ARM_SUBSCRIPTION_ID) to locate an existing container group before running 'az container stop'. Override for tenants/orgs outside the default ESLZ subscriptions."
  type        = list(string)
  default     = ["G3Mc-CTO-ENT-MRZ", "GcPc-CTO-ENT-CORE"]
}
