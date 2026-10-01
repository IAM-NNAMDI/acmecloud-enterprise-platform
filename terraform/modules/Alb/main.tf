#======================================================================
# 1. Create a Public web Application Load Balancer (ALB)
#======================================================================
resource "aws_lb" "web" {

  name = "${local.name_prefix}-web-alb"

  internal = false

  load_balancer_type = "application"

  security_groups = [
    var.alb_sg_id
  ]

  subnets = var.public_subnet_ids

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-web-alb"
      Tier = "Public"
    }
  )
}

#======================================================================
# 2. Web ALB Target Group
#======================================================================

resource "aws_lb_target_group" "web" {

  name = "${local.name_prefix}-web-tg"

  port = var.web_http_port

  protocol = "HTTP"

  vpc_id = var.vpc_id

  health_check {

    path = var.web_health_path

    protocol = "HTTP"

    healthy_threshold = 2

    unhealthy_threshold = 2

    timeout = 5

    interval = 30

    matcher = "200"
  }

  tags = local.common_tags
}

#======================================================================
# 3. Attach Apache ASG
#======================================================================
resource "aws_autoscaling_attachment" "web" {

  autoscaling_group_name = var.web_asg_name

  lb_target_group_arn = aws_lb_target_group.web.arn
}

#======================================================================
# 4. Web ALB Listener
#======================================================================

resource "aws_lb_listener" "web_http" {

  load_balancer_arn = aws_lb.web.arn

  port = var.web_http_port

  protocol = "HTTP"

  default_action {

    type = "forward"

    target_group_arn = aws_lb_target_group.web.arn
  }
}

#======================================================================
# 5. Internal App Application Load Balancer (ALB)
#======================================================================

resource "aws_lb" "app" {

  name = "${local.name_prefix}-app-alb"

  internal = true

  load_balancer_type = "application"

  security_groups = [
    var.app_alb_sg_id
  ]

  subnets = var.private_app_subnet_ids

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-app-alb"
      Tier = "Private"
    }
  )
}

#======================================================================
# 6. App ALB Target Group
#======================================================================

resource "aws_lb_target_group" "app" {

  name = "${local.name_prefix}-app-tg"

  port = var.app_port

  protocol = "HTTP"

  vpc_id = var.vpc_id

  health_check {

    path = var.app_health_path

    protocol = "HTTP"

    healthy_threshold = 2

    unhealthy_threshold = 2

    timeout = 5

    interval = 30

    matcher = "200"
  }

  tags = local.common_tags
}

#======================================================================
# 7. Attach Tomcat ASG
#======================================================================

resource "aws_autoscaling_attachment" "app" {

  autoscaling_group_name = var.app_asg_name

  lb_target_group_arn = aws_lb_target_group.app.arn
}

#======================================================================
# 8. Internal Listener
#======================================================================

resource "aws_lb_listener" "app_http" {

  load_balancer_arn = aws_lb.app.arn

  port = var.app_port

  protocol = "HTTP"

  default_action {

    type = "forward"

    target_group_arn = aws_lb_target_group.app.arn
  }
}

