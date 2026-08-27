include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_terragrunt_dir()}/../../modules//platform"
}

locals {
  environment = "prod"
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

  vpc_cidr           = "10.2.0.0/16"
  azs                = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets     = ["10.2.0.0/24", "10.2.1.0/24", "10.2.2.0/24"]
  private_subnets    = ["10.2.10.0/24", "10.2.11.0/24", "10.2.12.0/24"]
  database_subnets   = ["10.2.20.0/24", "10.2.21.0/24", "10.2.22.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = false
  enable_flow_log    = true

  kubernetes_version               = "1.34"
  eks_endpoint_public_access = false
  eks_instance_type          = "t3.large"
  enable_bastion             = true
  create_ssm_vpc_endpoints   = true

  rds_identifier              = "aws-devops-prod"
  rds_engine                  = "postgres"
  rds_engine_version          = "16"
  rds_family                  = "postgres16"
  rds_major_engine_version    = "16"
  rds_instance_class          = "db.t4g.medium"
  rds_allocated_storage       = 50
  rds_db_name                 = "appdb"
  rds_username                = "appadmin"
  rds_multi_az                = true
  rds_backup_retention_period = 14
  rds_deletion_protection     = true
  rds_skip_final_snapshot     = false

  static_bucket_name = "aws-devops-prod-static-CHANGE-ME"
}
