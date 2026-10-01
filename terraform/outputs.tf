# ============================================================
# AcmeCloud Enterprise Platform
# Root Outputs
# ============================================================

# ============================================================
# VPC OUTPUTS
# ============================================================

output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block."
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs."
  value       = module.vpc.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "Private database subnet IDs."
  value       = module.vpc.private_db_subnet_ids
}

output "internet_gateway_id" {
  description = "Internet Gateway ID."
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID."
  value       = module.vpc.nat_gateway_id
}

# ============================================================
# SECURITY OUTPUTS
# ============================================================

output "bastion_security_group_id" {
  description = "Bastion Host Security Group."
  value       = module.security.bastion_sg_id
}

output "alb_security_group_id" {
  description = "Public ALB Security Group."
  value       = module.security.alb_sg_id
}

output "web_security_group_id" {
  description = "Apache Web Tier Security Group."
  value       = module.security.web_sg_id
}

output "app_security_group_id" {
  description = "Tomcat Application Tier Security Group."
  value       = module.security.app_sg_id
}

output "app_alb_security_group_id" {
  description = "Internal Application Load Balancer Security Group."
  value       = module.security.app_alb_sg_id
}

output "redis_security_group_id" {
  description = "Redis Security Group."
  value       = module.security.redis_sg_id
}

output "database_security_group_id" {
  description = "Database Security Group."
  value       = module.security.database_sg_id
}

# ============================================================
# COMPUTE OUTPUTS
# ============================================================

output "bastion_instance_id" {
  description = "Bastion Host instance ID."
  value       = module.compute.bastion_id
}

output "bastion_public_ip" {
  description = "Public IP of the Bastion Host."
  value       = module.compute.bastion_public_ip
}

output "web_auto_scaling_group" {
  description = "Apache Auto Scaling Group."
  value       = module.compute.web_asg_name
}

output "app_auto_scaling_group" {
  description = "Tomcat Auto Scaling Group."
  value       = module.compute.app_asg_name
}

output "web_launch_template_id" {
  description = "Apache Launch Template."
  value       = module.compute.web_launch_template_id
}

output "app_launch_template_id" {
  description = "Tomcat Launch Template."
  value       = module.compute.app_launch_template_id
}

output "ec2_instance_profile" {
  description = "IAM Instance Profile used by EC2."
  value       = module.compute.ec2_instance_profile
}

# ============================================================
# LOAD BALANCER OUTPUTS
# ============================================================

output "web_alb_dns_name" {
  description = "Public Web ALB DNS name."
  value       = module.alb.web_alb_dns_name
}

output "web_alb_arn" {
  description = "Public Web ALB ARN."
  value       = module.alb.web_alb_arn
}

output "web_target_group_arn" {
  description = "Web Target Group ARN."
  value       = module.alb.web_target_group_arn
}

output "internal_app_alb_dns_name" {
  description = "Internal Application ALB DNS."
  value       = module.alb.app_alb_dns_name
}

output "internal_app_alb_arn" {
  description = "Internal Application ALB ARN."
  value       = module.alb.app_alb_arn
}

output "app_target_group_arn" {
  description = "Application Target Group ARN."
  value       = module.alb.app_target_group_arn
}

# ============================================================
# DATABASE OUTPUTS
# ============================================================

output "database_endpoint" {
  description = "RDS MySQL endpoint."
  value       = module.database.db_endpoint
}

output "database_port" {
  description = "RDS MySQL port."
  value       = module.database.db_port
}

output "database_name" {
  description = "Application database name."
  value       = module.database.db_name
}

output "redis_primary_endpoint" {
  description = "Primary Redis endpoint."
  value       = module.database.redis_primary_endpoint
}

output "redis_reader_endpoint" {
  description = "Redis reader endpoint."
  value       = module.database.redis_reader_endpoint
}

# ============================================================
# STORAGE / IDENTITY OUTPUTS
# ============================================================

output "s3_bucket_name" {
  description = "Application assets bucket."
  value       = module.storage_identity.s3_bucket_name
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN."
  value       = module.storage_identity.s3_bucket_arn
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID."
  value       = module.storage_identity.cognito_user_pool_id
}

output "cognito_app_client_id" {
  description = "Cognito App Client ID."
  value       = module.storage_identity.cognito_client_id
}

output "signup_lambda_name" {
  description = "Signup Lambda function."
  value       = module.storage_identity.lambda_function_name
}

output "signup_lambda_arn" {
  description = "Signup Lambda ARN."
  value       = module.storage_identity.lambda_function_arn
}

# ============================================================
# DEPLOYMENT SUMMARY
# ============================================================

output "deployment_summary" {
  description = "High-level deployment summary."

  value = {
    project      = var.project_name
    environment  = var.environment
    region       = var.aws_region
    vpc          = module.vpc.vpc_id
    web_alb      = module.alb.web_alb_dns_name
    bastion_ip   = module.compute.bastion_public_ip
    database     = module.database.db_endpoint
    redis        = module.database.redis_primary_endpoint
    bucket       = module.storage_identity.s3_bucket_name
    cognito_pool = module.storage_identity.cognito_user_pool_id
    lambda       = module.storage_identity.lambda_function_name
  }
}