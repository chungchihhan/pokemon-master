variable "aws_region" {
  description = "aws region"
  type        = string
  default = "ap-northeast-1"
}

variable "service_name" {
  description = "Service name"
  type        = string
  default = "pokemon"
}

variable "bucket_name"{
  description = "Bucket name"
  type        = string
  default = "pokemon-master-frontend"
}