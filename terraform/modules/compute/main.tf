#======================================================================
# 1. IAM ROLE/ EC2 Assume Role Policy
#======================================================================

data "aws_iam_policy_document" "ec2_assume_role" {

  statement {

    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "ec2.amazonaws.com"
      ]
    }
  }
}

#======================================================================
# 2. IAM ROLE
#======================================================================

resource "aws_iam_role" "ec2" {

  name = "${local.name_prefix}-ec2-role"

  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = local.common_tags
}

#======================================================================
# 3. SSM Policy Attachment
#======================================================================

resource "aws_iam_role_policy_attachment" "ssm" {

  role = aws_iam_role.ec2.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#======================================================================
# CloudWatch Agent Policy Attachment
#======================================================================

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {

  role = aws_iam_role.ec2.name

  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

#======================================================================
# 4. EC2 Instance Profile
#======================================================================

resource "aws_iam_instance_profile" "ec2" {

  name = "${local.name_prefix}-ec2-instance-profile"

  role = aws_iam_role.ec2.name
}

#======================================================================
# 5. Bastion Host
#======================================================================

resource "aws_instance" "bastion" {

  ami                    = var.ami_id
  instance_type          = var.bastion_instance_type
  subnet_id              = var.public_subnet_ids[0]
  key_name               = var.key_name
  vpc_security_group_ids = [var.bastion_sg_id]

  iam_instance_profile = aws_iam_instance_profile.ec2.name

  user_data = file("${path.module}/userdata/bastion.sh")

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-bastion"
      Tier = "Public"
    }
  )
}

#======================================================================
# 6. Apache Launch Template
#======================================================================

resource "aws_launch_template" "web" {

  name_prefix = "${local.name_prefix}-web-"

  image_id = var.ami_id

  instance_type = var.web_instance_type

  key_name = var.key_name

  vpc_security_group_ids = [
    var.web_sg_id
  ]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  user_data = base64encode(file("${path.module}/userdata/apache.sh"))

  tag_specifications {

    resource_type = "instance"

    tags = merge(
      local.common_tags,
      {
        Name = "${local.name_prefix}-apache"
        Tier = "Web"
      }
    )
  }
}

#======================================================================
# 7. Apache Auto Scaling Group
#======================================================================

resource "aws_autoscaling_group" "web" {

  name = "${local.name_prefix}-web-asg"

  min_size         = var.web_min_size
  max_size         = var.web_max_size
  desired_capacity = var.web_desired_capacity

  vpc_zone_identifier = var.public_subnet_ids

  health_check_type = "EC2"

  launch_template {

    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {

    key                 = "Name"
    value               = "${local.name_prefix}-apache"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [
      min_size,
      desired_capacity
    ]
  }
}

#======================================================================
# 8. Tomcat Launch Template
#======================================================================

resource "aws_launch_template" "app" {

  name_prefix = "${local.name_prefix}-app-"

  image_id = var.ami_id

  instance_type = var.app_instance_type

  key_name = var.key_name

  vpc_security_group_ids = [
    var.app_sg_id
  ]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  user_data = base64encode(file("${path.module}/userdata/tomcat.sh"))

  tag_specifications {

    resource_type = "instance"

    tags = merge(
      local.common_tags,
      {
        Name = "${local.name_prefix}-tomcat"
        Tier = "Application"
      }
    )
  }
}

#======================================================================
# 9. Tomcat Auto Scaling Group
#======================================================================

resource "aws_autoscaling_group" "app" {

  name = "${local.name_prefix}-app-asg"

  min_size         = var.app_min_size
  max_size         = var.app_max_size
  desired_capacity = var.app_desired_capacity

  vpc_zone_identifier = var.private_app_subnet_ids

  health_check_type = "EC2"

  launch_template {

    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {

    key                 = "Name"
    value               = "${local.name_prefix}-tomcat"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [
      min_size,
      desired_capacity
    ]
  }
}