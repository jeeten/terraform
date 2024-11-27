variable "server_port" {
    description = "http request port"
    default = 80
    type = number

    validation {
      condition = var.server_port > 0 && var.server_port < 65535
      error_message = "This port number must be between 1-65535"
      
    }

    sensitive = true # it will hide from terraform output console log
}