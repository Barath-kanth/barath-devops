# Shared Terragrunt config for all environments.
# Each env includes this file and supplies its own `inputs`.

locals {
  project = "aws-devops-assessment"
}

# ---------------------------------------------------------------------------
# Remote state (enable when the S3 bucket + lock table exist)
# Separate key per env path → isolation / no cross-env blast radius.
#
# Example keys after enable:
#   aws-devops-assessment/dev/terraform.tfstate
#   aws-devops-assessment/stage/terraform.tfstate
#   aws-devops-assessment/prod/terraform.tfstate
# ---------------------------------------------------------------------------
# remote_state {
#   backend = "s3"
#   disable_init = true # Terragrunt won't auto-create bucket; you create it once
#
#   generate = {
#     path      = "backend.tf"
#     if_exists = "overwrite_terragrunt"
#   }
#
#   config = {
#     bucket         = "YOUR_TF_STATE_BUCKET"
#     key            = "${local.project}/${path_relative_to_include()}/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "YOUR_TF_LOCK_TABLE"
#     encrypt        = true
#   }
# }

generate "versions" {
  path      = "versions_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
EOF
}
