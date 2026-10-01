#======================================================================1. Bastion Security Group
#======================================================================

resource "aws_security_group" "bastion" {

  name        = "${local.name_prefix}-bastion-sg"
  description = "Security group for Bastion Host"
  vpc_id      = var.vpc_id

  ingress {

    description = "SSH from trusted administrator"

    from_port = var.ssh_port
    to_port   = var.ssh_port
    protocol  = "tcp"

    cidr_blocks = [
      var.bastion_allowed_cidr
    ]
  }

  egress {

    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-bastion-sg"
    }
  )
}

#======================================================================2. Application Security Group
#======================================================================
resource "aws_security_group" "alb" {

  name        = "${local.name_prefix}-alb-sg"
  description = "Public Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {

    from_port = var.http_port
    to_port   = var.http_port
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {

    from_port = var.https_port
    to_port   = var.https_port
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {

    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-alb-sg"
    }
  )
}



#======================================================================3. Web Security Group
#======================================================================

resource "aws_security_group" "web" {

  name        = "${local.name_prefix}-web-sg"
  description = "Apache Web Servers"
  vpc_id      = var.vpc_id

  ingress {

    description = "HTTP from ALB"

    from_port = var.http_port
    to_port   = var.http_port
    protocol  = "tcp"

    security_groups = [
      aws_security_group.alb.id
    ]
  }

  egress {

    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-web-sg"
    }
  )
}

#======================================================================
# 4. Internal Application ALB Security Group
#======================================================================

resource "aws_security_group" "app_alb" {

  name        = "${local.name_prefix}-app-alb-sg"
  description = "Internal Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {

    description = "Application traffic from Web Servers"

    from_port = var.app_port
    to_port   = var.app_port
    protocol  = "tcp"

    security_groups = [
      aws_security_group.web.id
    ]
  }

  egress {

    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-app-alb-sg"
    }
  )
}

#======================================================================4. Application Security Group
#======================================================================

resource "aws_security_group" "app" {

  name        = "${local.name_prefix}-app-sg"
  description = "Tomcat Application Servers"
  vpc_id      = var.vpc_id

  ingress {

    description = "Application traffic from Internal App ALB"

    from_port = var.app_port
    to_port   = var.app_port
    protocol  = "tcp"

    security_groups = [
      aws_security_group.app_alb.id
    ]
  }

  ingress {

    description = "SSH from Bastion"

    from_port = var.ssh_port
    to_port   = var.ssh_port
    protocol  = "tcp"

    security_groups = [
      aws_security_group.bastion.id
    ]
  }

  egress {

    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-app-sg"
    }
  )
}

#======================================================================5. Redis Security Group
#======================================================================

resource "aws_security_group" "redis" {

  name        = "${local.name_prefix}-redis-sg"
  description = "Redis Cache"
  vpc_id      = var.vpc_id

  ingress {

    description = "Redis from App Servers"

    from_port = var.redis_port
    to_port   = var.redis_port
    protocol  = "tcp"

    security_groups = [
      aws_security_group.app.id
    ]
  }

  egress {

    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-redis-sg"
    }
  )
}

#======================================================================6. Database Security Group
#======================================================================
resource "aws_security_group" "database" {

  name        = "${local.name_prefix}-db-sg"
  description = "RDS MySQL"
  vpc_id      = var.vpc_id

  ingress {

    description = "MySQL from App Servers"

    from_port = var.db_port
    to_port   = var.db_port
    protocol  = "tcp"

    security_groups = [
      aws_security_group.app.id
    ]
  }

  egress {

    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-db-sg"
    }
  )
}

