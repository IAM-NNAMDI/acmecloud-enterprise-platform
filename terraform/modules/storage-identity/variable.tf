variable "project_name" { type = string }
variable "environment" { type = string }
variable "owner" { type = string }

variable "s3_bucket_name" {
  type = string
}

variable "lambda_runtime" {
  default = "python3.12"
}

variable "lambda_memory_size" {
  default = 128
}

variable "lambda_timeout" {
  default = 10
}

variable "cognito_user_pool_name" {
  default = "acmecloud-users"
}

variable "additional_tags" {
  default = {}
}