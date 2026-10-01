#======================================================================
# 1. DB Subnet Group
#======================================================================

resource "aws_db_subnet_group" "this" {

  name = "${local.name_prefix}-db-subnets"

  subnet_ids = var.private_db_subnet_ids

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-db-subnets"
    }
  )
}

#======================================================================
# 2. Redis subnet group
#======================================================================

resource "aws_elasticache_subnet_group" "this" {

  name = "${local.name_prefix}-redis-subnets"

  subnet_ids = var.private_db_subnet_ids
}

#====================================================================== #. 3 RDS Parameter Group
#======================================================================

resource "aws_db_parameter_group" "mysql" {

  name = "${local.name_prefix}-mysql"

  family = "mysql8.0"

  tags = local.common_tags
}

#======================================================================
# 4. RDS MySQL Database
#======================================================================

resource "aws_db_instance" "mysql" {

  identifier = "${local.name_prefix}-mysql"

  engine = "mysql"

  engine_version = var.db_engine_version

  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage

  max_allocated_storage = var.db_max_allocated_storage

  storage_encrypted = true

  db_name = var.db_name

  username = var.db_username

  password = var.db_password

  db_subnet_group_name = aws_db_subnet_group.this.name

  vpc_security_group_ids = [
    var.database_sg_id
  ]

  parameter_group_name = aws_db_parameter_group.mysql.name

  multi_az = var.db_multi_az

  backup_retention_period = var.db_backup_retention_period

  deletion_protection = var.db_deletion_protection

  publicly_accessible = false

  skip_final_snapshot = var.db_skip_final_snapshot

  apply_immediately = true

  port = var.db_port

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-mysql"
      Tier = "Database"
    }
  )
}

#======================================================================
# 5. Redis Parameter Group
#======================================================================

resource "aws_elasticache_parameter_group" "redis" {

  name = "${local.name_prefix}-redis"

  family = "redis7"

  description = "AcmeCloud Redis Parameter Group"
}

#======================================================================
# 6. Redis Replication Group
#======================================================================

resource "aws_elasticache_replication_group" "redis" {

  replication_group_id = "${local.name_prefix}-redis"

  description = "AcmeCloud Redis"

  node_type = var.redis_node_type

  port = var.redis_port

  subnet_group_name = aws_elasticache_subnet_group.this.name

  security_group_ids = [
    var.redis_sg_id
  ]

  num_cache_clusters = 2

  automatic_failover_enabled = true

  multi_az_enabled = true

  at_rest_encryption_enabled = true

  transit_encryption_enabled = true

  parameter_group_name = aws_elasticache_parameter_group.redis.name

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-redis"
      Tier = "Cache"
    }
  )
}

