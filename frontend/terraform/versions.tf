terraform {
  required_version = "~> 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.84.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.1"
    }
  }
}
