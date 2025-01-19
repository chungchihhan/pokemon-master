variable "aws_region" {
  description = "aws region"
  type        = string
  default = "ap-northeast-1"
}

variable "dynamodb_table" {
  description = "DynamoDB table name"
  type        = string
  default = "pokemon_table"
}

variable "docker_host" {
  description = "Docker host"
  type        = string
  default = "unix:///Users/chungchihhan/.docker/run/docker.sock"
}

