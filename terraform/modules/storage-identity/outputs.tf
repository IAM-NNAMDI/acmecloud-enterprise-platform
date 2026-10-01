output "s3_bucket_name" {
  value = aws_s3_bucket.assets.bucket
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.assets.arn
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.users.id
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.web.id
}

output "lambda_function_name" {
  value = aws_lambda_function.signup.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.signup.arn
}