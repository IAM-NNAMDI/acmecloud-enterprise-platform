variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "owner" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "bastion_allowed_cidr" {
  type = string
}

variable "ssh_port" {
  type    = number
  default = 22
}

variable "http_port" {
  type    = number
  default = 80
}

variable "https_port" {
  type    = number
  default = 443
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "redis_port" {
  type    = number
  default = 6379
}

variable "db_port" {
  type    = number
  default = 3306
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}