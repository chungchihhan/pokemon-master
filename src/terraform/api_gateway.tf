locals {
  region = var.aws_region

  tags = {
    Service = var.service_name
  }
}

################################################################################
# API Gateway Module
################################################################################

module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "5.0.0"

  description = "Pokemon Master api gateway to lambda container image"
  name        = "${var.service_name}"

  create_domain_name    = false
  create_domain_records = false
  create_certificate    = false


  cors_configuration = {
    allow_headers     = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods     = ["*"]
    allow_origins     = ["http://localhost:3000", "http://localhost:5500", "https://*", "http://*"]
    allow_credentials = true
  }

  fail_on_warnings = false

  disable_execute_api_endpoint = false

  # Routes & Integration(s)
  routes = {
    "POST /pokemon/{pokemon_name}" = {
      detailed_metrics_enabled = true
      throttling_rate_limit    = 80
      throttling_burst_limit   = 40

      integration = {
        uri                    = module.search_pokemon_lambda.lambda_function_arn # Remember to change
        type                   = "AWS_PROXY"
        payload_format_version = "1.0"
        timeout_milliseconds   = 29000
      }
    }
    "GET /pokemons" = {
      detailed_metrics_enabled = true
      throttling_rate_limit    = 80
      throttling_burst_limit   = 40

      integration = {
        uri                    = module.list_pokemons_lambda.lambda_function_arn # Remember to change
        type                   = "AWS_PROXY"
        payload_format_version = "1.0"
        timeout_milliseconds   = 29000
      }
    }
  }

  # Stage
  stage_access_log_settings = {
    create_log_group            = true
    log_group_retention_in_days = 7
    format = jsonencode({
      context = {
        domainName              = "$context.domainName"
        integrationErrorMessage = "$context.integrationErrorMessage"
        protocol                = "$context.protocol"
        requestId               = "$context.requestId"
        requestTime             = "$context.requestTime"
        responseLength          = "$context.responseLength"
        routeKey                = "$context.routeKey"
        stage                   = "$context.stage"
        status                  = "$context.status"
        error = {
          message      = "$context.error.message"
          responseType = "$context.error.responseType"
        }
        identity = {
          sourceIP = "$context.identity.sourceIp"
        }
        integration = {
          error             = "$context.integration.error"
          integrationStatus = "$context.integration.integrationStatus"
        }
      }
    })
  }

  stage_default_route_settings = {
    detailed_metrics_enabled = true
    throttling_burst_limit   = 5
    throttling_rate_limit    = 10
  }

  tags = local.tags
}

