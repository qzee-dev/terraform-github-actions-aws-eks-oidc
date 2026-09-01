variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "github_org" {
  description = "GitHub Organization or Username"
  type        = string
}

variable "github_repo" {
  description = "GitHub Repository Name"
  type        = string
}

variable "github_branch" {
  description = "GitHub Branch allowed to assume role"
  type        = string
}

variable "eks_cluster_name" {
  description = "EKS Cluster Name"
  type        = string
}

variable "ecr_repository_name" {
  description = "ECR Repository Name"
  type        = string
}

variable "role_name" {
  description = "GitHub OIDC Role Name"
  type        = string
}
