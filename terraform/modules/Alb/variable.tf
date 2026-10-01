variable "project_name" { type = string }

variable "environment" { type = string }

variable "owner" { type = string }

variable "vpc_id" { type = string }

variable "public_subnet_ids" { type = list(string) }

variable "private_app_subnet_ids" { type = list(string) }

variable "alb_sg_id" { type = string }

variable "web_sg_id" { type = string }

variable "app_alb_sg_id" { type = string }

variable "web_asg_name" { type = string }

variable "app_asg_name" { type = string }

variable "web_http_port" {
  default = 80
}

variable "web_https_port" {
  default = 443
}

variable "app_port" {
  default = 8080
}

variable "web_health_path" {
  default = "/"
}

variable "app_health_path" {
  default = "/"
}

variable "additional_tags" {
  default = {}
}