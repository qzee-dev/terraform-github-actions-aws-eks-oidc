#####################################
# Data Sources
#####################################

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_eks_cluster" "eks" {
  name = var.eks_cluster_name
}

data "aws_ecr_repository" "repo" {
  name = var.ecr_repository_name
}

#####################################
# GitHub OIDC Provider
#####################################

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

#####################################
# IAM Trust Policy
#####################################

data "aws_iam_policy_document" "github_oidc_trust" {

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
        "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.github_branch}"
      ]
    }
  }
}

#####################################
# IAM Role
#####################################

resource "aws_iam_role" "github_actions_role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.github_oidc_trust.json

  tags = {
    ManagedBy = "Terraform"
    Purpose   = "GitHubOIDC"
  }
}

#####################################
# Permission Policy
#####################################

resource "aws_iam_policy" "github_actions_policy" {

  name = "${var.role_name}-policy"

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Sid    = "EKSAccess"
        Effect = "Allow"

        Action = [
          "eks:DescribeCluster"
        ]

        Resource = data.aws_eks_cluster.eks.arn
      },

      {
        Sid    = "ECRAuthorization"
        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken"
        ]

        Resource = "*"
      },

      {
        Sid    = "ECRPush"
        Effect = "Allow"

        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]

        Resource = data.aws_ecr_repository.repo.arn
      }
    ]
  })
}

#####################################
# Attach Policy To Role
#####################################

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_actions_policy.arn
}

