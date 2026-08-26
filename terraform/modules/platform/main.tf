locals {
  name = "${var.project_name}-${var.environment}"

  tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

################################################################################
# Network
################################################################################

module "network" {
  source = "../network"

  name   = local.name
  cidr   = var.vpc_cidr
  azs    = var.azs
  region = var.aws_region
  tags   = local.tags

  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  database_subnets = var.database_subnets

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  create_database_subnet_group       = true
  create_database_subnet_route_table = true

  enable_flow_log                      = var.enable_flow_log
  create_flow_log_cloudwatch_log_group = var.enable_flow_log
  create_flow_log_cloudwatch_iam_role  = var.enable_flow_log

  # ALB discovery (public) + Karpenter discovery (private)
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = local.name
  }
}

################################################################################
# EKS (bootstrap MNG + Karpenter-ready tags/OIDC)
################################################################################

module "eks" {
  source = "../eks"

  name   = local.name
  region = var.aws_region
  tags   = local.tags

  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.private_subnets

  kubernetes_version = var.kubernetes_version

  endpoint_private_access = true
  endpoint_public_access  = var.eks_endpoint_public_access

  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = true

  instance_type = var.eks_instance_type

  addons = {
    coredns = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
    eks-pod-identity-agent = {
      before_compute = true
    }
  }
}

################################################################################
# RDS (private DB subnets + SG limited to EKS nodes)
################################################################################

resource "aws_security_group" "rds" {
  name_prefix = "${local.name}-rds-"
  description = "PostgreSQL access from EKS nodes only"
  vpc_id      = module.network.vpc_id

  ingress {
    description     = "Postgres from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name}-rds" })
}

module "rds" {
  source = "../rds"

  identifier = var.rds_identifier
  region     = var.aws_region
  tags       = local.tags

  engine               = var.rds_engine
  engine_version       = var.rds_engine_version
  family               = var.rds_family
  major_engine_version = var.rds_major_engine_version
  instance_class       = var.rds_instance_class

  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_allocated_storage * 2
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.rds_db_name
  username = var.rds_username
  port     = 5432

  manage_master_user_password = true
  publicly_accessible         = false
  multi_az                    = var.rds_multi_az

  create_db_subnet_group = true
  subnet_ids             = module.network.database_subnets
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = var.rds_backup_retention_period
  deletion_protection     = var.rds_deletion_protection
  skip_final_snapshot     = var.rds_skip_final_snapshot

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true
}

################################################################################
# S3 static origin (private; CloudFront OAC reads via bucket policy below)
################################################################################

module "s3" {
  source = "../s3"

  bucket = var.static_bucket_name
  region = var.aws_region

  # Module-managed deny policies off so a single combined policy can include OAC
  attach_deny_insecure_transport_policy    = false
  attach_require_latest_tls_policy         = false
  attach_deny_incorrect_encryption_headers = false
  attach_deny_unencrypted_object_uploads   = false

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
}

################################################################################
# CloudFront → S3 (OAC)
################################################################################

module "cloudfront" {
  source = "../cloudfront"

  tags    = local.tags
  comment = "${local.name} static site"

  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  is_ipv6_enabled     = true

  origin_access_control = {
    s3 = {
      description      = "OAC for ${local.name} static bucket"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  origin = {
    s3 = {
      domain_name               = module.s3.s3_bucket_bucket_regional_domain_name
      origin_access_control_key = "s3"
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    # AWS managed CachingOptimized
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  viewer_certificate = {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  restrictions = {
    geo_restriction = {
      restriction_type = "none"
    }
  }
}

# Combined bucket policy: HTTPS-only + CloudFront OAC read
data "aws_iam_policy_document" "static_bucket" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      module.s3.s3_bucket_arn,
      "${module.s3.s3_bucket_arn}/*",
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid     = "AllowCloudFrontServicePrincipalRead"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = ["${module.s3.s3_bucket_arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.cloudfront.cloudfront_distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "static" {
  bucket = module.s3.s3_bucket_id
  policy = data.aws_iam_policy_document.static_bucket.json
}
