## Providers

| Name    | Version |
| ------- | ------- |
| azurerm | 4.0.0   |
| null    | n/a     |

## Inputs

| Name              | Description                                                                                       | Type          | Default           | Required |
| ----------------- | ------------------------------------------------------------------------------------------------- | ------------- | ----------------- | :------: |
| container\_group  | Object containing all container group parameters                                                  | `any`         | `{}`              |    no    |
| env               | (Required) env value                                                                              | `string`      | n/a               |   yes    |
| extra\_env\_vars  | Variables used in case it is easier to set a container environment variable as a variable in ESLZ | `any`         | `{}`              |    no    |
| location          | (Required) Azure location where the container group will be placed                                | `string`      | `"canadacentral"` |    no    |
| resource\_groups  | Resource group object containing all resource groups                                              | `any`         | `{}`              |    no    |
| subnets           | Object containing all subnets in the project                                                      | `any`         | `{}`              |    no    |
| tags              | Tags to be applied to the container group                                                         | `map(string)` | `{}`              |    no    |
| userDefinedString | (Required) UserDefinedString part of the name of the container group                              | `string`      | n/a               |   yes    |

## Outputs

| Name                   | Description                 |
| ---------------------- | --------------------------- |
| container\_group       | Container group object      |
| container\_group\_id   | ID of the container group   |
| container\_group\_name | Name of the container group |

## Extra Environment variables

A special extra_env_vars variable is available to be set in the root module in a client's ESLZ project. This variable can be useful to pass tokens to the ACI, or any variables built in to the ESLZ template.

## Identity

If the target container image resides in an Azure Container registry behind a private endpoint, the ACI will need the AcrPull role on the target ACR to successfully deploy. Therefore, the ACI will need to be configured with either a SystemAssigned identity or an already existing user assigned 

## Stop Containers

An option to stop_containers is present to automatically stop the containers after creation to save on billing. Set this value to true for Devops pipeline agents. 

## TFVARS Parameter

| Parameter Name    | Possible Values                 | Required | Default    |
| ----------------- | ------------------------------- | -------- | ---------- |
| `name`            | string                          | Yes      | n/a        |
| `resource_group`  | string or ID                    | Yes      | n/a        |
| `os_type`         | Windows,Linux                   | Yes      | n/a        |
| `sku`             | Confidential,Dedicated,Standard | No       | "Standard" |
| `ip_address_type` | Public,Private,None             | No       | "Private"  |
| `subnet`          | string or ID                    | Yes      | n/a        |
| `restart_policy`  | Always,Never,OnFailure          | No       | "Always"   |
| `priority`        | Regular,Spot                    | No       | null       |
| `tags`            | map of string                   | No       | {}         |
| `stop_containers` | true,false                      | No       | false      |

#### Image_Registry_Credential Block

One of username/password or user_assigned_identity_id need to be set. This block is required.  

| Parameter Name                                        | Possible Values | Required | Default |
| ----------------------------------------------------- | --------------- | -------- | ------- |
| `server`                    | string          | Yes      | n/a     |
| `username`                  | string          | No       | null    |
| `password`                  | string          | No       | null    |
| `user_assigned_identity_id` | ID              | No       | null    |

#### dns_config Block

This block is Required. Change DNS server addresses depending on P3 and P6

| Parameter Name           | Possible Values | Required | Default |
| ------------------------ | --------------- | -------- | ------- |
| `nameservers` | IP addresses    | Yes      | n/a     |

#### Container Block

| Parameter Name                    | Possible Values | Required | Default |
| --------------------------------- | --------------- | -------- | ------- |
| `name`                  | string          | Yes      | n/a     |
| `image`                 | string          | Yes      | n/a     |
| `cpu`                   | int             | Yes      | n/a     |
| `memory`                | int             | Yes      | n/a     |
| `cpu_limit`             | int             | No       | null    |
| `memory_limit`          | int             | No       | null    |
| `commands`              | list of string  | No       | null    |
| `port`                  | int             | Yes      | n/a     |
| `protocol`              | string          | No       | "TCP"   |
| `environment_variables` | map of string   | No       | {}      |

#### Identity Block

| Parameter Name          | Possible Values             | Required | Default |
| ----------------------- | --------------------------- | -------- | ------- |
| `type`         | SystemAssigned,UserAssigned | Yes      | n/a     |
| `identity_ids` | list of IDs                 | No       | []      |

