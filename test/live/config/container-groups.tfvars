# config/container-groups.tfvars
# Minimal, valid fixture exercising the module's common path: a single
# public-image container on a private subnet, legacy single port/protocol
# keys (rather than the `ports` list) - matches real-world ESLZ usage.

container_group = {
  resource_group = "live_test"
  os_type        = "Linux"
  subnet         = "live_test"

  container = [
    {
      name     = "live-test-agent"
      image    = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
      cpu      = 1
      memory   = 1.5
      port     = 80
      protocol = "TCP"
      environment_variables = {
        "LIVE_TEST" = "true"
      }
    }
  ]
}
