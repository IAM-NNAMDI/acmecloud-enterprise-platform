variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "owner" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "key_name" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_app_subnet_ids" {
  type = list(string)
}

variable "bastion_sg_id" {
  type = string
}

variable "web_sg_id" {
  type = string
}

variable "app_sg_id" {
  type = string
}

variable "bastion_instance_type" {
  default = "t3.micro"
}

variable "web_instance_type" {
  default = "t3.micro"
}

variable "app_instance_type" {
  default = "t3.micro"
}

variable "web_min_size" {
  default = 2
}

variable "web_desired_capacity" {
  default = 2
}

variable "web_max_size" {
  default = 4
}

variable "app_min_size" {
  default = 2
}

variable "app_desired_capacity" {
  default = 2
}

variable "app_max_size" {
  default = 4
}

variable "additional_tags" {
  default = {}
}