output "bastion_sg_id" {
  value = aws_security_group.bastion.id
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "web_sg_id" {
  value = aws_security_group.web.id
}

output "app_sg_id" {
  value = aws_security_group.app.id
}

output "app_alb_sg_id" {
  value = aws_security_group.app_alb.id
}

output "redis_sg_id" {
  value = aws_security_group.redis.id
}

output "database_sg_id" {
  value = aws_security_group.database.id
}
