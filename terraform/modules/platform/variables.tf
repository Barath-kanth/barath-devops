variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project name used in resource names"
  type        = string
  default     = "aws-devops"
}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "tags" {
  description = "Common tags applied via provider default_tags and modules"
  type        = map(string)
  default     = {}
}

################################################################################
# Network
################################################################################

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "database_subnets" {
  type    = list(string)
  default = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

variable "enable_flow_log" {
  type    = bool
  default = true
}

################################################################################
# EKS
################################################################################

variable "kubernetes_version" {
  type    = string
  default = "1.34"
}

variable "eks_endpoint_public_access" {
  description = "Public EKS API. Prefer false + bastion/SSM port-forward for secure access."
  type        = bool
  default     = true
}

variable "eks_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "enable_bastion" {
  description = "Deploy private SSM bastion for EKS API access (no SSH)"
  type        = bool
  default     = true
}

variable "bastion_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "create_ssm_vpc_endpoints" {
  description = "Interface VPC endpoints so private bastion can use SSM"
  type        = bool
  default     = true
}

################################################################################
# RDS
################################################################################

variable "rds_identifier" {
  type = string
}

variable "rds_engine" {
  type    = string
  default = "postgres"
}

variable "rds_engine_version" {
  type    = string
  default = "16"
}

variable "rds_family" {
  type    = string
  default = "postgres16"
}

variable "rds_major_engine_version" {
  type    = string
  default = "16"
}

variable "rds_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "rds_allocated_storage" {
  type    = number
  default = 20
}

variable "rds_db_name" {
  type    = string
  default = "appdb"
}

variable "rds_username" {
  type    = string
  default = "appadmin"
}

variable "rds_multi_az" {
  type    = bool
  default = false
}

variable "rds_backup_retention_period" {
  type    = number
  default = 7
}

variable "rds_deletion_protection" {
  type    = bool
  default = true
}

variable "rds_skip_final_snapshot" {
  type    = bool
  default = false
}

################################################################################
# S3 / CloudFront
################################################################################

variable "static_bucket_name" {
  description = "Globally unique S3 bucket name for static site origin"
  type        = string
}
