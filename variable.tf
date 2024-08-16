variable "tags" {
  description = "Tags to be applied to the container group"
  type        = map(string)
  default     = {}
}

variable "userDefinedString" {
  description = "(Required) USerDefinedStrin part of the name of the container group"
  type        = string
}

variable "env" {
  description = "(Required) env value"
  type        = string
}

variable "group" {
  description = "(Required) Group value for the container group"
  type = string
}

variable "project" {
  description = "(Required) Project value for the container group"
  type = string
}

variable "location" {
  description = "(Required) Azure location where the container group will be placed"
  type = string
  default = "canadacentral"
}

variable "resource_groups" {
  description = "Resource group object containing all resource groups"
  type = any
  default = {}
}

variable "container_group" {
  description = "Object containing all container group parameters"
  type = any
  default = {}
}

variable "subnets" {
  description = "Object containing all subnets in the project"
  type = any
  default = {}
}

variable "extra_env_vars" {
  description = "Variables used in case it is easier to set a container environment variable as a variable in ESLZ"
  type = any
  default = {}
}