containerGroup = {
  "pipelineAgent" = {
    resource_group  = "Management"
    os_type         = "Linux"
    subnet          = "OZ"
    stop_containers = true

    image_registry_credentials = {
      server   = "devopspipeline.azurecr.io"
      username = "devopspipeline"
      password = ""
    }

    dns_config = {
      nameservers = ["172.16.16.132", "172.16.16.133"]
    }

    container = [
      {
        name     = "pipelineagent1"
        image    = "devopspipeline.azurecr.io/pipeline-agent:3.0"
        cpu      = 1
        memory   = 1.5
        port     = 80
        protocol = "TCP"
        # cpu_limit = try(container.value["cpu_limit"], null)
        # memory_limit = try(container.value["memory_limit"], null)
        # commands = try(container.value["commands"], null)
        environment_variables = { "AZP_URL" = "https://dev.azure.com/Azure163g3-CloudOperations",
        "AZP_POOL" = "MaxPool", "AZP_AGENT_NAME" = "DockerAgent1" }
      }
    ]
  }
}
