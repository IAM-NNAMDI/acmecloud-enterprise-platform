variable "project_name" { type = string }
variable "environment" { type = string }
variable "owner" { type = string }

variable "private_db_subnet_ids" {
  type = list(string)
}

variable "private_app_subnet_ids" {
  type = list(string)
}

variable "database_sg_id" {
  type = string
}

variable "redis_sg_id" {
  type = string
}

variable "db_engine_version" {
  default = "8.0"
}

variable "db_instance_class" {
  default = "db.t3.micro"
}

variable "db_name" {
  default = "acmecloud"
}

variable "db_username" {
  default = "acmeadmin"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_allocated_storage" {
  default = 20
}

variable "db_max_allocated_storage" {
  default = 100
}

variable "db_backup_retention_period" {
  default = 7
}

variable "db_multi_az" {
  default = true
}

variable "db_port" {
  default = 3306
}

variable "redis_node_type" {
  default = "cache.t3.micro"
}

variable "redis_port" {
  default = 6379
}

variable "additional_tags" {
  default = {}
}
variable "db_deletion_protection" {
  description = "Enable deletion protection for the RDS instance"
  type        = bool
  default     = true
}

variable "db_skip_final_snapshot" {
  description = "Skip the final RDS snapshot when deleting the database"
  type        = bool
  default     = false
}