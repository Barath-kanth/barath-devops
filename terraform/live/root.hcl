# Shared Terragrunt config for all environments.
# Each env includes this file and supplies its own `inputs`.
#
# Backend: S3 + native lockfile (no DynamoDB). Requires Terraform >= 1.11.
# Create the bucket once (versioning + encryption on), then:
#   cd live/dev && terragrunt init

locals {
  project      = "aws-devops-assessment"
  aws_region   = "us-east-1"
  # Unique bucket — change if this name is taken
  state_bucket = "barath-devops-tfstate-927120871634"
}

# ---------------------------------------------------------------------------
# Remote state — separate key per env (dev / stage / prod)
# Generated file: backend.tf (do not hand-edit)
# ---------------------------------------------------------------------------
remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket       = local.state_bucket
    key          = "${local.project}/${path_relative_to_include()}/terraform.tfstate"
    region       = local.aws_region
    encrypt      = true
    use_lockfile = true
  }
}

generate "versions" {
  path      = "versions_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
EOF
}
