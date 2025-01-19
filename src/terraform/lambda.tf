data "aws_ecr_authorization_token" "token" {
}

data "aws_caller_identity" "this" {}

resource "random_string" "this" {
  length  = 4
  special = false
  lower   = true
  upper   = false
}

locals {
  source_path = "${path.module}/.."
  search_pokemon_function_name_and_ecr_repo_name     = "search_pokemon-${random_string.this.result}"
  path_include                                    = ["**"]
  path_exclude                                    = ["**/__pycache__/**"]
  files_include                                   = setunion([for f in local.path_include : fileset(local.source_path, f)]...)
  files_exclude                                   = setunion([for f in local.path_exclude : fileset(local.source_path, f)]...)
  files                                           = sort(setsubtract(local.files_include, local.files_exclude))
  dir_sha                                         = sha1(join("", [for f in local.files : filesha1("${local.source_path}/${f}")]))
}

provider "docker" {
  host = var.docker_host

  registry_auth {
    address  = format("%v.dkr.ecr.%v.amazonaws.com", data.aws_caller_identity.this.account_id, var.aws_region)
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
  }
}
####################################
####################################
####################################
# POST /pokemon ####################
####################################
####################################
####################################

module "search_pokemon_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.7.0"

  function_name  = local.search_pokemon_function_name_and_ecr_repo_name
  description    = "Pokemon Master: POST /pokemon/{pokemon_name} "
  create_package = false
  timeout        = 30

  ##################
  # Container Image
  ##################
  package_type = "Image"
  # architectures = ["x86_64"] # or ["arm64"]
  architectures = ["arm64"]
  image_uri = module.search_pokemon_docker_image.image_uri

  publish = true # Whether to publish creation/change as new Lambda Function Version.

  environment_variables = {
    "DYNAMODB_TABLE" = var.dynamodb_table
  }

  # allowed_triggers = {
  #   AllowExecutionFromAPIGateway = {
  #     service    = "apigateway"
  #     source_arn = "${module.api_gateway.api_execution_arn}/*/*"
  #   }
  # }

  tags = {
    "Terraform"   = "true",
  }
  ######################
  # Additional policies
  ######################

  attach_policy_statements = true
  policy_statements = {
    dynamodb_crud = {
      effect = "Allow",
      actions = [
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:UpdateItem"
      ],
      resources = [
        "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.this.account_id}:table/${var.dynamodb_table}"
      ]
    },
  }

}

module "search_pokemon_docker_image" {
  source  = "terraform-aws-modules/lambda/aws//modules/docker-build"
  version = "7.7.0"

  create_ecr_repo      = true
  keep_remotely        = true
  use_image_tag        = false
  image_tag_mutability = "MUTABLE"
  ecr_repo             = local.search_pokemon_function_name_and_ecr_repo_name
  ecr_repo_lifecycle_policy = jsonencode({
    "rules" : [
      {
        "rulePriority" : 1,
        "description" : "Keep only the last 10 images",
        "selection" : {
          "tagStatus" : "any",
          "countType" : "imageCountMoreThan",
          "countNumber" : 10
        },
        "action" : {
          "type" : "expire"
        }
      }
    ]
  })

  source_path = "${local.source_path}/search_pokemon/"
  triggers = {
    dir_sha = local.dir_sha
  }
}
