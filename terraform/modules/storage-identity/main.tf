#======================================================================
#.1 S3 Bucket
#======================================================================
resource "aws_s3_bucket" "assets" {

  bucket = var.s3_bucket_name

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-assets"
      Tier = "Storage"
    }
  )
}

#======================================================================
#.2 s3 versioning
#======================================================================

resource "aws_s3_bucket_versioning" "assets" {

  bucket = aws_s3_bucket.assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

#======================================================================
#.3 Encryption
#======================================================================

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {

  bucket = aws_s3_bucket.assets.id

  rule {

    apply_server_side_encryption_by_default {

      sse_algorithm = "AES256"
    }
  }
}

#======================================================================
#.4 Public Access Block
#======================================================================

resource "aws_s3_bucket_public_access_block" "assets" {

  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

#======================================================================
#.5 Lifecycle Rule
#======================================================================

resource "aws_s3_bucket_lifecycle_configuration" "assets" {

  bucket = aws_s3_bucket.assets.id

  rule {

    id = "archive"

    status = "Enabled"

    filter {}

    transition {

      days = 30

      storage_class = "STANDARD_IA"
    }
  }
}

#======================================================================
# Cognito Resources
# 6. User Pool
#======================================================================

resource "aws_cognito_user_pool" "users" {

  name = var.cognito_user_pool_name

  username_attributes = [
    "email"
  ]

  auto_verified_attributes = [
    "email"
  ]

  password_policy {

    minimum_length = 8

    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = true
  }

  tags = local.common_tags
}

#======================================================================
# 7. App Client
#======================================================================

resource "aws_cognito_user_pool_client" "web" {

  name = "${local.name_prefix}-web-client"

  user_pool_id = aws_cognito_user_pool.users.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}

#======================================================================
# IAM Role/Lambda needs permissions.

# 8. Assume Role
#======================================================================

data "aws_iam_policy_document" "lambda_assume" {

  statement {

    actions = ["sts:AssumeRole"]

    principals {

      type = "Service"

      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
  }
}

#======================================================================
# 9. IAM Role
#======================================================================

resource "aws_iam_role" "lambda" {

  name = "${local.name_prefix}-lambda-role"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json

  tags = local.common_tags
}

#======================================================================
# 10. Logging Permissions
#======================================================================

resource "aws_iam_role_policy_attachment" "lambda_logs" {

  role = aws_iam_role.lambda.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#======================================================================
# 11. Lambda Function
#======================================================================

resource "aws_lambda_function" "signup" {

  filename = "${path.module}/lambda/signup.zip"

  function_name = "${local.name_prefix}-signup"

  role = aws_iam_role.lambda.arn

  handler = "lambda_function.lambda_handler"

  runtime = var.lambda_runtime

  memory_size = var.lambda_memory_size

  timeout = var.lambda_timeout

  source_code_hash = filebase64sha256("${path.module}/lambda/signup.zip")

  tags = local.common_tags
}

#======================================================================
# 12. Cognito trigger 
#======================================================================

resource "aws_lambda_permission" "cognito" {

  statement_id = "AllowExecutionFromCognito"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.signup.function_name

  principal = "cognito-idp.amazonaws.com"

  source_arn = aws_cognito_user_pool.users.arn
}

#======================================================================
# 13. Cognito User Pool Lambda Config attachment
#======================================================================

resource "aws_cognito_user_pool" "admin_users" {

  name = var.cognito_user_pool_name

  username_attributes = ["email"]

  auto_verified_attributes = ["email"]

  lambda_config {

    post_confirmation = aws_lambda_function.signup.arn
  }

  password_policy {

    minimum_length = 8

    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = true
  }

  tags = local.common_tags
}

