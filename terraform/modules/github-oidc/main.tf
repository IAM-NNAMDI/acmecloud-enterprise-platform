locals {
  role_name = "${var.project_name}-${var.environment}-github-actions"
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = merge(
    var.tags,
    {
      Name      = "${var.project_name}-${var.environment}-github-oidc"
      Component = "cicd"
    }
  )
}

data "aws_iam_policy_document" "github_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"

      values = [
        "sts.amazonaws.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "repo:IAM-NNAMDI@117322301/acmecloud-enterprise-platform@1398869728:ref:refs/heads/main"
      ]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json

  tags = merge(
    var.tags,
    {
      Name      = local.role_name
      Component = "cicd"
    }
  )
}

data "aws_iam_policy_document" "ecr_push" {
  statement {
    sid = "ECRAuthentication"

    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = ["*"]
  }

  statement {
    sid = "ECRPushPull"

    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]

    resources = var.ecr_repository_arns
  }
}

resource "aws_iam_role_policy" "ecr_push" {
  name   = "${local.role_name}-ecr"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.ecr_push.json
}


# ============================================================
# Amazon EKS deployment access
# ============================================================

data "aws_iam_policy_document" "eks_deploy" {
  count = var.eks_cluster_arn != null ? 1 : 0

  statement {
    sid    = "DescribeAcmeCloudEKS"
    effect = "Allow"

    actions = [
      "eks:DescribeCluster"
    ]

    resources = [
      var.eks_cluster_arn
    ]
  }
}

resource "aws_iam_role_policy" "eks_deploy" {
  count = var.eks_cluster_arn != null ? 1 : 0

  name   = "${local.role_name}-eks"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.eks_deploy[0].json
}
