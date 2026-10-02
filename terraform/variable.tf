# ============================================================
# AcmeCloud Enterprise Platform
# Global Terraform Variables
# ============================================================


# ============================================================
# 1. PROJECT / ENVIRONMENT CONFIGURATION
# ============================================================

variable "project_name" {
  description = "Name of the AcmeCloud project."
  type        = string
  default     = "acmecloud"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name must contain only lowercase letters, numbers, and hyphens."
  }
}


variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "production"

  validation {
    condition = contains(
      ["dev", "staging", "production"],
      var.environment
    )
    error_message = "environment must be dev, staging, or production."
  }
}


variable "owner" {
  description = "Team or individual responsible for the infrastructure."
  type        = string
  default     = "AcmeCloud DevOps"
}


variable "cost_center" {
  description = "Cost center used for AWS resource tagging."
  type        = string
  default     = "acmecloud-platform"
}


# ============================================================
# 2. AWS REGION
# ============================================================

variable "aws_region" {
  description = "AWS region where the infrastructure will be deployed."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS region format, for example us-east-1."
  }
}


# ============================================================
# 3. AVAILABILITY ZONES
# ============================================================

variable "availability_zones" {
  description = "Availability Zones used by the AcmeCloud production environment."
  type        = list(string)

  default = [
    "eu-west-2a",
    "eu-west-2b"
  ]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two Availability Zones are required for high availability."
  }
}


# ============================================================
# 4. VPC CONFIGURATION
# ============================================================

variable "vpc_cidr" {
  description = "CIDR block for the AcmeCloud VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}


variable "enable_dns_support" {
  description = "Enable DNS resolution inside the VPC."
  type        = bool
  default     = true
}


variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames inside the VPC."
  type        = bool
  default     = true
}


# ============================================================
# 5. PUBLIC SUBNETS
# ============================================================

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets."
  type        = list(string)

  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Exactly two public subnet CIDRs are required for the two-AZ architecture."
  }
}


# ============================================================
# 6. PRIVATE APPLICATION SUBNETS
# ============================================================

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for the private application subnets."
  type        = list(string)

  default = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]

  validation {
    condition     = length(var.private_app_subnet_cidrs) == 2
    error_message = "Exactly two private application subnet CIDRs are required."
  }
}


# ============================================================
# 7. PRIVATE DATABASE SUBNETS
# ============================================================

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for the private database subnets."
  type        = list(string)

  default = [
    "10.0.21.0/24",
    "10.0.22.0/24"
  ]

  validation {
    condition     = length(var.private_db_subnet_cidrs) == 2
    error_message = "Exactly two private database subnet CIDRs are required."
  }
}


# ============================================================
# 8. NAT GATEWAY
# ============================================================

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet outbound internet access."
  type        = bool
  default     = true
}


variable "single_nat_gateway" {
  description = "Use a single NAT Gateway instead of one NAT Gateway per AZ."
  type        = bool
  default     = true
}

# ============================================================
# 9. LOAD BALANCER
# ============================================================

variable "enable_alb" {
  description = "Enable Application Load Balancers and associated resources."
  type        = bool
  default     = true
}

# ============================================================
# 10. DATA TIER
# ============================================================

variable "enable_data_tier" {
  description = "Enable the RDS MySQL and ElastiCache Redis data tier."
  type        = bool
  default     = true
}


# ============================================================
# 9. BASTION HOST
# ============================================================

variable "enable_bastion" {
  description = "Whether to deploy a bastion host."
  type        = bool
  default     = true
}


variable "bastion_instance_type" {
  description = "EC2 instance type for the bastion host."
  type        = string
  default     = "t3.micro"
}


variable "bastion_key_name" {
  description = "Existing AWS EC2 key pair used to access the bastion host."
  type        = string
}


variable "bastion_allowed_cidr" {
  description = "CIDR block allowed to SSH into the bastion host."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.bastion_allowed_cidr))
    error_message = "bastion_allowed_cidr must be a valid IPv4 CIDR block."
  }
}


# ============================================================
# 10. EC2 / APPLICATION CONFIGURATION
# ============================================================

variable "ami_id" {
  description = "AMI ID used for the EC2 instances."
  type        = string
}


variable "web_instance_type" {
  description = "EC2 instance type for Apache web servers."
  type        = string
  default     = "t3.micro"
}


variable "app_instance_type" {
  description = "EC2 instance type for Tomcat application servers."
  type        = string
  default     = "t3.micro"
}


# ============================================================
# 11. WEB AUTO SCALING GROUP
# ============================================================

variable "web_min_size" {
  description = "Minimum number of Apache web servers."
  type        = number
  default     = 2

  validation {
    condition     = var.web_min_size >= 2
    error_message = "The web tier must have at least two instances for high availability."
  }
}


variable "web_desired_capacity" {
  description = "Desired number of Apache web servers."
  type        = number
  default     = 2
}


variable "web_max_size" {
  description = "Maximum number of Apache web servers."
  type        = number
  default     = 4
}


# ============================================================
# 12. APPLICATION AUTO SCALING GROUP
# ============================================================

variable "app_min_size" {
  description = "Minimum number of Tomcat application servers."
  type        = number
  default     = 2

  validation {
    condition     = var.app_min_size >= 2
    error_message = "The application tier must have at least two instances for high availability."
  }
}


variable "app_desired_capacity" {
  description = "Desired number of Tomcat application servers."
  type        = number
  default     = 2
}


variable "app_max_size" {
  description = "Maximum number of Tomcat application servers."
  type        = number
  default     = 4
}


# ============================================================
# 13. WEB APPLICATION LOAD BALANCER
# ============================================================

variable "web_alb_internal" {
  description = "Whether the web ALB is internal."
  type        = bool
  default     = false
}


variable "web_alb_port" {
  description = "Port exposed by the web Application Load Balancer."
  type        = number
  default     = 80
}


variable "web_target_port" {
  description = "Port used by Apache web servers."
  type        = number
  default     = 80
}


variable "web_health_check_path" {
  description = "Health check path for Apache web servers."
  type        = string
  default     = "/"
}


# ============================================================
# 14. APPLICATION LOAD BALANCER
# ============================================================

variable "app_alb_internal" {
  description = "Whether the application ALB is internal."
  type        = bool
  default     = true
}


variable "app_alb_port" {
  description = "Port exposed by the internal application ALB."
  type        = number
  default     = 8080
}


variable "app_target_port" {
  description = "Port used by Tomcat application servers."
  type        = number
  default     = 8080
}


variable "app_health_check_path" {
  description = "Health check path for Tomcat application servers."
  type        = string
  default     = "/"
}


# ============================================================
# 15. REDIS / ELASTICACHE
# ============================================================

variable "enable_redis" {
  description = "Enable Amazon ElastiCache for Redis."
  type        = bool
  default     = true
}


variable "redis_node_type" {
  description = "ElastiCache Redis node type."
  type        = string
  default     = "cache.t3.micro"
}


variable "redis_num_cache_nodes" {
  description = "Number of Redis cache nodes."
  type        = number
  default     = 2

  validation {
    condition     = var.redis_num_cache_nodes >= 1
    error_message = "At least one Redis cache node is required."
  }
}


variable "redis_port" {
  description = "Redis port."
  type        = number
  default     = 6379
}


# ============================================================
# 16. RDS MYSQL
# ============================================================

variable "enable_rds" {
  description = "Enable Amazon RDS for MySQL."
  type        = bool
  default     = true
}


variable "db_engine" {
  description = "Database engine."
  type        = string
  default     = "mysql"
}


variable "db_engine_version" {
  description = "MySQL engine version."
  type        = string
  default     = "8.0"
}


variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}


variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "acmecloud"
}


variable "db_username" {
  description = "Master username for the RDS database."
  type        = string
  default     = "acmeadmin"

  sensitive = true
}


variable "db_password" {
  description = "Master password for the RDS database."
  type        = string
  sensitive   = true
}


variable "db_allocated_storage" {
  description = "Initial RDS storage size in GB."
  type        = number
  default     = 20
}


variable "db_max_allocated_storage" {
  description = "Maximum storage RDS can automatically scale to in GB."
  type        = number
  default     = 100
}


variable "db_multi_az" {
  description = "Enable Multi-AZ deployment for RDS."
  type        = bool
  default     = true
}


variable "db_backup_retention_period" {
  description = "Number of days automated RDS backups are retained."
  type        = number
  default     = 7

  validation {
    condition     = var.db_backup_retention_period >= 1
    error_message = "RDS backup retention must be at least one day."
  }
}


variable "db_port" {
  description = "MySQL database port."
  type        = number
  default     = 3306
}


variable "db_deletion_protection" {
  description = "Prevent accidental deletion of the production database."
  type        = bool
  default     = true
}


variable "db_skip_final_snapshot" {
  description = "Skip the final RDS snapshot when destroying the database."
  type        = bool
  default     = false
}


# ============================================================
# 17. S3
# ============================================================

variable "enable_s3" {
  description = "Enable the AcmeCloud S3 bucket."
  type        = bool
  default     = true
}


variable "s3_bucket_name" {
  description = "Globally unique S3 bucket name."
  type        = string
}


variable "s3_versioning_enabled" {
  description = "Enable S3 object versioning."
  type        = bool
  default     = true
}


variable "s3_force_destroy" {
  description = "Allow Terraform to delete a non-empty S3 bucket."
  type        = bool
  default     = false
}


# ============================================================
# 18. COGNITO
# ============================================================

variable "enable_cognito" {
  description = "Enable Amazon Cognito."
  type        = bool
  default     = true
}


variable "cognito_user_pool_name" {
  description = "Name of the Cognito User Pool."
  type        = string
  default     = "acmecloud-users"
}


variable "cognito_username_attributes" {
  description = "Attributes that can be used as usernames."
  type        = list(string)

  default = [
    "email"
  ]
}


variable "cognito_auto_verified_attributes" {
  description = "Cognito attributes that should be automatically verified."
  type        = list(string)

  default = [
    "email"
  ]
}


# ============================================================
# 19. LAMBDA
# ============================================================

variable "enable_signup_lambda" {
  description = "Enable the signup Lambda function."
  type        = bool
  default     = true
}


variable "lambda_runtime" {
  description = "Runtime used by the signup Lambda."
  type        = string
  default     = "python3.12"
}


variable "lambda_handler" {
  description = "Lambda function handler."
  type        = string
  default     = "lambda_function.lambda_handler"
}


variable "lambda_memory_size" {
  description = "Memory allocated to the Lambda function."
  type        = number
  default     = 128
}


variable "lambda_timeout" {
  description = "Lambda execution timeout in seconds."
  type        = number
  default     = 10
}


# ============================================================
# 20. SSH CONFIGURATION
# ============================================================

variable "ssh_port" {
  description = "SSH port used by Linux EC2 instances."
  type        = number
  default     = 22
}


# ============================================================
# 21. HTTP / HTTPS
# ============================================================

variable "http_port" {
  description = "HTTP port."
  type        = number
  default     = 80
}


variable "https_port" {
  description = "HTTPS port."
  type        = number
  default     = 443
}


# ============================================================
# 22. TAGGING
# ============================================================

variable "additional_tags" {
  description = "Additional tags applied to all supported AWS resources."
  type        = map(string)

  default = {}
}

variable "key_name" {
  description = "EC2 Key Pair name used for the Bastion and Auto Scaling instances."
  type        = string
}

variable "app_port" {
  description = "Port used by the Tomcat application."
  type        = number
  default     = 8080
}
variable "web_health_path" {
  description = "Health check path for the public Web ALB."
  type        = string
  default     = "/"
}

variable "app_health_path" {
  description = "Health check path for the internal App ALB."
  type        = string
  default     = "/"
}

# ============================================================
# 11. AMAZON EKS
# ============================================================

variable "enable_eks" {
  description = "Enable the Amazon EKS cluster and supporting resources."
  type        = bool
  default     = true
}
