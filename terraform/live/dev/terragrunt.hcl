include "root" {
  path = find_in_parent_folders("root.hcl")
}

# `//platform` copies sibling modules so platform's `source = "../network"` etc. resolve.
terraform {
  source = "${get_terragrunt_dir()}/../../modules//platform"
}

locals {
  environment = "dev"
  aws_region  = "us-east-1"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"

  default_tags {
    tags = {
      Environment = "${local.environment}"
      ManagedBy   = "terraform"
      Project     = "aws-devops"
    }
  }
}
EOF
}

inputs = {
  aws_region   = local.aws_region
  project_name = "aws-devops"
  environment  = local.environment

  tags = {
    Owner = "barath"
  }

  vpc_cidr           = "10.0.0.0/16"
  azs                = ["us-east-1a", "us-east-1b"]
  public_subnets     = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets    = ["10.0.10.0/24", "10.0.11.0/24"]
  database_subnets   = ["10.0.20.0/24", "10.0.21.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true
  enable_flow_log    = true

  kubernetes_version         = "1.34"
  eks_endpoint_public_access = true
  eks_instance_type          = "t3.medium"

  rds_identifier              = "aws-devops-dev"
  rds_engine                  = "postgres"
  rds_engine_version          = "16"
  rds_family                  = "postgres16"
  rds_major_engine_version    = "16"
  rds_instance_class          = "db.t4g.micro"
  rds_allocated_storage       = 20
  rds_db_name                 = "appdb"
  rds_username                = "appadmin"
  rds_multi_az                = false
  rds_backup_retention_period = 7
  rds_deletion_protection     = false
  rds_skip_final_snapshot     = true

  static_bucket_name = "aws-devops-dev-static-CHANGE-ME"
}
