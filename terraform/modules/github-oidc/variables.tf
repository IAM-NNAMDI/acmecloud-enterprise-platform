variable "project_name" {
  description = "Project name used for resource naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in owner/repository format."
  type        = string
}

variable "ecr_repository_arns" {
  description = "ECR repository ARNs GitHub Actions may push images to."
  type        = list(string)
}

variable "tags" {
  description = "Additional resource tags."
  type        = map(string)
  default     = {}
}
