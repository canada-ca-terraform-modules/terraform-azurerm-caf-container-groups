# terraform-azurerm-caf-container-groups

Terraform module to deploy an Azure Container Group (ACI) following the ESLZ naming convention `{env}SLD-{userDefinedString}-ci`.

## Known Behavior

`azurerm_container_group.container_group` marks the `container` block `ignore_changes` in its `lifecycle` block, because per the [provider docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_group) nearly every argument on this resource — including every `container` sub-attribute — forces resource replacement. Without this, routine plans would propose destroying and recreating the group whenever container image/env/command drift is detected. To intentionally apply a container change, run:

```shell
terragrunt apply -replace='module.containerGroups["<key>"].azurerm_container_group.container_group'
```

`stop_containers = true` (via `null_resource.local-exec-stop`) searches the subscriptions in `stop_container_probe_subscriptions` (default `["G3Mc-CTO-ENT-MRZ", "GcPc-CTO-ENT-CORE"]`) plus the caller's active `$ARM_SUBSCRIPTION_ID` for an existing container group before calling `az container stop`. Override `stop_container_probe_subscriptions` for tenants/orgs outside the default ESLZ subscriptions.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 5.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 5.0 |
| <a name="provider_null"></a> [null](#provider\_null) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_container_group.container_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_group) | resource |
| [null_resource.local-exec-stop](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_container_group"></a> [container\_group](#input\_container\_group) | Object containing all container group parameters | `any` | `{}` | no |
| <a name="input_env"></a> [env](#input\_env) | (Required) env value | `string` | n/a | yes |
| <a name="input_extra_env_vars"></a> [extra\_env\_vars](#input\_extra\_env\_vars) | Variables used in case it is easier to set a container environment variable as a variable in ESLZ | `any` | `{}` | no |
| <a name="input_group"></a> [group](#input\_group) | (Optional) Group value — used to preserve legacy naming convention {env}-{group}-{project}-{userDefinedString} | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | (Required) Azure location where the container group will be placed | `string` | `"canadacentral"` | no |
| <a name="input_project"></a> [project](#input\_project) | (Optional) Project value — used to preserve legacy naming convention {env}-{group}-{project}-{userDefinedString} | `string` | `null` | no |
| <a name="input_resource_groups"></a> [resource\_groups](#input\_resource\_groups) | Resource group object containing all resource groups | `any` | `{}` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Object containing all subnets in the project | `any` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to be applied to the container group | `map(string)` | `{}` | no |
| <a name="input_userDefinedString"></a> [userDefinedString](#input\_userDefinedString) | (Required) UserDefinedString part of the name of the container group | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_container_group"></a> [container\_group](#output\_container\_group) | Container group object |
| <a name="output_container_group_id"></a> [container\_group\_id](#output\_container\_group\_id) | ID of the container group |
| <a name="output_container_group_name"></a> [container\_group\_name](#output\_container\_group\_name) | Name of the container group |
<!-- END_TF_DOCS -->
