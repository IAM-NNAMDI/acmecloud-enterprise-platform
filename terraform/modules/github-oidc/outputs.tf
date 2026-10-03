output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "role_arn" {
  description = "ARN of the IAM role assumed by GitHub Actions."
  value       = aws_iam_role.github_actions.arn
}

output "role_name" {
  description = "Name of the IAM role assumed by GitHub Actions."
  value       = aws_iam_role.github_actions.name
}
