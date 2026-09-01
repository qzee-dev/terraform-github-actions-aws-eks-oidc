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



#######################################################################
to create oidc provider for githubaction
#######################################################################
resource "aws_iam_openid_connect_provider" "github" {

  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

##########################################################################
Create IAM Role
##########################################################################
resource "aws_iam_role" "github_actions" {

  name = "GithubOIDCAdminRoleFor_fintech-platform"

  assume_role_policy = data.aws_iam_policy_document.github_oidc_trust.json
}

##########################################################################
IAM role Trust policy
#########################################################################
data "aws_iam_policy_document" "github_oidc_trust" {

  statement {

    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type        = "Federated"
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
        "repo:qzee-dev/fintech-platform:ref:refs/heads/main"
        "repo:qzee-dev/fintech-platform:ref:refs/heads/develop"
      ]
    }
  }
}
#
#"repo:qzee-dev/fintech-platform:*" (all branch)
##########################################################################################
IAM role Permision Policy
##########################################################################################
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_policy" "github_actions_policy" {

  name = "GithubActionsECRAndEKS"

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Sid = "EKSAccess"

        Effect = "Allow"

        Action = [
          "eks:DescribeCluster"
        ]

        Resource = aws_eks_cluster.main.arn
      },

      {
        Sid = "ECRAuth"

        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken"
        ]

        Resource = "*"
      },

      {
        Sid = "ECRPush"

        Effect = "Allow"

        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage"
        ]

        Resource = aws_ecr_repository.application.arn
      }
    ]
  })
}

############################################################################
IAM Role Attachment
############################################################################
resource "aws_iam_role_policy_attachment" "github_attach" {

  role = aws_iam_role.github_actions.name

  policy_arn = aws_iam_policy.github_actions_policy.arn
}



































