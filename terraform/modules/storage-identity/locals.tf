locals {

  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "storage-identity"
      Owner       = var.owner
    },
    var.additional_tags
  )
}