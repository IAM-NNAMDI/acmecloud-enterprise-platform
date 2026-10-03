# ============================================================
# AcmeCloud Enterprise Platform
# Root Module Wiring
# ============================================================

# ------------------------------------------------------------
# 1. VPC MODULE
# ------------------------------------------------------------

module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  owner        = var.owner

  vpc_cidr                 = var.vpc_cidr
  availability_zones       = var.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs

  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway

  additional_tags = var.additional_tags
}

# ------------------------------------------------------------
# 2. SECURITY MODULE
# ------------------------------------------------------------

module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  owner        = var.owner

  vpc_id = module.vpc.vpc_id

  bastion_allowed_cidr = var.bastion_allowed_cidr

  ssh_port   = var.ssh_port
  http_port  = var.http_port
  https_port = var.https_port
  app_port   = var.app_port
  redis_port = var.redis_port
  db_port    = var.db_port

  additional_tags = var.additional_tags
}

# ------------------------------------------------------------
# 3. COMPUTE MODULE
# ------------------------------------------------------------

module "compute" {
  source = "./modules/compute"

  project_name = var.project_name
  environment  = var.environment
  owner        = var.owner

  ami_id   = var.ami_id
  key_name = var.key_name

  public_subnet_ids      = module.vpc.public_subnet_ids
  private_app_subnet_ids = module.vpc.private_app_subnet_ids

  bastion_sg_id = module.security.bastion_sg_id
  web_sg_id     = module.security.web_sg_id
  app_sg_id     = module.security.app_sg_id

  bastion_instance_type = var.bastion_instance_type
  web_instance_type     = var.web_instance_type
  app_instance_type     = var.app_instance_type

  web_min_size         = var.web_min_size
  web_desired_capacity = var.web_desired_capacity
  web_max_size         = var.web_max_size

  app_min_size         = var.app_min_size
  app_desired_capacity = var.app_desired_capacity
  app_max_size         = var.app_max_size

  additional_tags = var.additional_tags

  depends_on = [
    module.vpc,
    module.security
  ]
}

# ------------------------------------------------------------
# 4. LOAD BALANCER MODULE
# ------------------------------------------------------------

module "alb" {
  count  = var.enable_alb ? 1 : 0
  source = "./modules/Alb"

  project_name = var.project_name
  environment  = var.environment
  owner        = var.owner

  vpc_id = module.vpc.vpc_id

  public_subnet_ids      = module.vpc.public_subnet_ids
  private_app_subnet_ids = module.vpc.private_app_subnet_ids

  alb_sg_id     = module.security.alb_sg_id
  web_sg_id     = module.security.web_sg_id
  app_alb_sg_id = module.security.app_alb_sg_id
  web_asg_name  = module.compute.web_asg_name
  app_asg_name  = module.compute.app_asg_name

  web_http_port   = var.http_port
  web_https_port  = var.https_port
  app_port        = var.app_port
  web_health_path = var.web_health_path
  app_health_path = var.app_health_path

  additional_tags = var.additional_tags

  depends_on = [
    module.compute
  ]
}

# ------------------------------------------------------------
# 5. DATABASE MODULE
# ------------------------------------------------------------

module "database" {
  count  = var.enable_data_tier ? 1 : 0
  source = "./modules/Database"

  project_name = var.project_name
  environment  = var.environment
  owner        = var.owner

  private_db_subnet_ids  = module.vpc.private_db_subnet_ids
  private_app_subnet_ids = module.vpc.private_app_subnet_ids

  database_sg_id = module.security.database_sg_id
  redis_sg_id    = module.security.redis_sg_id

  db_deletion_protection     = var.db_deletion_protection
  db_skip_final_snapshot     = var.db_skip_final_snapshot
  db_engine_version          = var.db_engine_version
  db_instance_class          = var.db_instance_class
  db_name                    = var.db_name
  db_username                = var.db_username
  db_password                = var.db_password
  db_allocated_storage       = var.db_allocated_storage
  db_max_allocated_storage   = var.db_max_allocated_storage
  db_backup_retention_period = var.db_backup_retention_period
  db_multi_az                = var.db_multi_az
  db_port                    = var.db_port

  redis_node_type = var.redis_node_type
  redis_port      = var.redis_port

  additional_tags = var.additional_tags

  depends_on = [
    module.security
  ]
}

# ------------------------------------------------------------
# 6. STORAGE & IDENTITY MODULE
# ------------------------------------------------------------

module "storage_identity" {
  source = "./modules/storage-identity"

  project_name = var.project_name
  environment  = var.environment
  owner        = var.owner

  s3_bucket_name         = var.s3_bucket_name
  cognito_user_pool_name = var.cognito_user_pool_name

  lambda_runtime     = var.lambda_runtime
  lambda_memory_size = var.lambda_memory_size
  lambda_timeout     = var.lambda_timeout

  additional_tags = var.additional_tags
}
# ==================================================
# Amazon EKS
# ==================================================

module "eks" {
  count  = var.enable_eks ? 1 : 0
  source = "./modules/eks"

  project_name = var.project_name
  environment  = var.environment

  private_subnet_ids = module.vpc.private_app_subnet_ids

  node_instance_types = ["t3.medium"]
  node_desired_size   = 2
  node_min_size       = 2
  node_max_size       = 4

  tags = merge(
    var.additional_tags,
    {
      Component = "eks"
    }
  )
}


# ============================================================
# GitHub Actions OIDC / CI-CD
# ============================================================

module "github_oidc" {
  source = "./modules/github-oidc"

  project_name      = var.project_name
  environment       = var.environment
  github_repository = "IAM-NNAMDI/acmecloud-enterprise-platform"

  ecr_repository_arns = [
    "arn:aws:ecr:us-east-1:944777361548:repository/acmecloud-web",
    "arn:aws:ecr:us-east-1:944777361548:repository/acmecloud-app"
  ]

  tags = merge(
    var.additional_tags,
    {
      Component = "cicd"
    }
  )
}
