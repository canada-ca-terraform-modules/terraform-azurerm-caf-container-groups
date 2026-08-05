# Because of issues with environment variables, Terraform ignores changes to the parameters inside the container block.
# (see `lifecycle { ignore_changes = [container] }` in module.tf and the "Known Behavior" section of README.md).
# To change any parameter in the container, you can execute the following command:
# terragrunt apply -replace='module.containerGroups["pipelineAgent"].azurerm_container_group.container_group'
containerGroup = {
  "pipelineAgent" = {
    resource_group = "Management"
    os_type        = "Linux"
    subnet         = "OZ"

    # Optional: Uncomment any of these values to change from the default
    # stop_containers = false          # Optional: Uncomment to stop the container upon creation
    # sku             = "Standard"     # Confidential | Dedicated | Standard
    # ip_address_type = "Private"      # Public | Private | None
    # restart_policy  = "Always"       # Always | Never | OnFailure
    # priority        = null           # Regular | Spot  (Spot requires ip_address_type = "None" and no subnet)
    # zones           = ["1"]          # Availability Zone list

    # DNS label (only for Public IP, not supported with Private)
    # dns_name_label             = "my-container"
    # dns_name_label_reuse_policy = "Noreuse"   # Noreuse | ResourceGroupReuse | SubscriptionReuse | TenantReuse | Unsecure

    # Customer-Managed Key encryption
    # key_vault_key_id                    = "/subscriptions/.../keys/mykey"
    # key_vault_user_assigned_identity_id = "/subscriptions/.../userAssignedIdentities/myid"

    # One of username/password or user_assigned_identity_id is required
    # Pass a single object (existing format) or a list for multiple registries:
    image_registry_credentials = {
      server   = "devopspipeline.azurecr.io"
      username = "devopspipeline"
      password = ""
      # user_assigned_identity_id = ""
    }
    # Multiple registries example:
    # image_registry_credentials = [
    #   { server = "registry1.azurecr.io", username = "user1", password = "pass1" },
    #   { server = "registry2.azurecr.io", user_assigned_identity_id = "/subscriptions/.../id" },
    # ]

    # DNS config is mandatory for ENT, uncomment the right block for your environment
    # P3
    dns_config = {
      nameservers = ["172.16.16.132", "172.16.16.133"]
      # search_domains = ["corp.example.com"]
      # options        = ["ndots:5"]
    }

    # P6
    # dns_config = {
    #   nameservers = ["10.150.17.12", "10.150.17.13"]
    # }

    # Log Analytics diagnostics
    # diagnostics = {
    #   log_analytics = {
    #     workspace_id  = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    #     workspace_key = "base64encodedkey=="
    #     log_type      = "ContainerInsights"   # ContainerInsights | ContainerInstanceLogs
    #   }
    # }

    # Group-level port exposure (must match ports exposed in at least one container)
    # exposed_port = [
    #   { port = 80,  protocol = "TCP" },
    #   { port = 443, protocol = "TCP" },
    # ]

    # Init containers (run before app containers; all args cause resource replacement)
    # init_container = [
    #   {
    #     name     = "init-setup"
    #     image    = "devopspipeline.azurecr.io/init:latest"
    #     commands = ["/bin/sh", "-c", "echo init done"]
    #     environment_variables        = { "INIT_VAR" = "value" }
    #     secure_environment_variables = { "SECRET_VAR" = "secret" }
    #   }
    # ]

    container = [
      {
        name   = "pipelineagent1"
        image  = "devopspipeline.azurecr.io/pipeline-agent:3.0"
        cpu    = 1
        memory = 1.5

        # Single port (existing format — still supported)
        port     = 80
        protocol = "TCP"

        # Multi-port format (new — use instead of port/protocol above)
        # ports = [
        #   { port = 80,  protocol = "TCP" },
        #   { port = 8080, protocol = "TCP" },
        # ]

        # cpu_limit    = null
        # memory_limit = null
        # commands     = null

        environment_variables = { "AZP_URL" = "https://dev.azure.com/Azure163g3-CloudOperations" }
        # secure_environment_variables = { "AZP_TOKEN" = "mysecrettoken" }

        # Azure Files volume mount
        # volumes = [
        #   {
        #     name                 = "myvolume"
        #     mount_path           = "/mnt/data"
        #     read_only            = false
        #     storage_account_name = "mystorageaccount"
        #     storage_account_key  = "base64key=="
        #     share_name           = "myshare"
        #   }
        # ]

        # Liveness probe example
        # liveness_probe = {
        #   http_get = { path = "/health", port = 80, scheme = "Http" }
        #   initial_delay_seconds = 10
        #   period_seconds        = 15
        #   failure_threshold     = 3
        # }

        # Readiness probe example
        # readiness_probe = {
        #   exec              = ["/bin/sh", "-c", "test -f /ready"]
        #   period_seconds    = 10
        #   failure_threshold = 3
        # }

        # Privileged container (Confidential SKU + Linux only)
        # security = { privilege_enabled = true }
      }
    ]

    # Managed Identity
    # identity = {
    #   type         = "SystemAssigned"           # SystemAssigned | UserAssigned | SystemAssigned, UserAssigned
    #   identity_ids = []                         # Required for UserAssigned
    # }
  }
}
