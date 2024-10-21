# Because of issues with environment variables, Terraform ignores changes to the parameters inside the container block. 
# To change any parameter in the container, you can execute the following command: 
# terragrunt apply -replace='module.containerGroups["pipelineAgent"].azurerm_container_group.container_group'
containerGroup = {
  "pipelineAgent" = {
    resource_group  = "Management"
    os_type         = "Linux"
    subnet          = "OZ"
    
    # Optional: Uncomment any of these values to change from the default
    # stop_containers = false          # Optional: Uncomment to stop the container upon creation
    # sku = try(var.container_group.sku, "Standard")
    # ip_address_type = "Private"
    # restart_policy = "Always"
    # priority = ""

    # One of username/password or user_assigned_identity_id is required
    image_registry_credentials = {
      server   = "devopspipeline.azurecr.io"
      username = "devopspipeline"
      password = ""
      # user_assigned_identity_id = ""
    }

    # DNS config is mandatory for ENT, uncomment the right block for your environment
    # P3 
    dns_config = {
      nameservers = ["172.16.16.132", "172.16.16.133"]
    }

    #P6
    # dns_config = {
    #   nameservers = ["10.150.17.12, 10.150.17.13"]
    # }

    container = [
      {
        name     = "pipelineagent1"
        image    = "devopspipeline.azurecr.io/pipeline-agent:3.0"
        cpu      = 1
        memory   = 1.5
        port     = 80
        protocol = "TCP"
        # cpu_limit = null
        # memory_limit = null
        # commands = null
        environment_variables = { "AZP_URL" = "https://dev.azure.com/Azure163g3-CloudOperations" }
      }
    ]
  }
}
