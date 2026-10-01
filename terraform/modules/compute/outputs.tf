output "bastion_id" {
  value = aws_instance.bastion.id
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "web_asg_name" {
  value = aws_autoscaling_group.web.name
}

output "app_asg_name" {
  value = aws_autoscaling_group.app.name
}

output "web_launch_template_id" {
  value = aws_launch_template.web.id
}

output "app_launch_template_id" {
  value = aws_launch_template.app.id
}

output "ec2_instance_profile" {
  value = aws_iam_instance_profile.ec2.name
}