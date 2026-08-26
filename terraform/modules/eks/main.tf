module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  create = var.create
  region = var.region
  tags   = var.tags

  # Cluster Core Configuration
  cluster_name                    = var.name
  cluster_version                 = var.kubernetes_version
  cluster_enabled_log_types       = var.enabled_log_types
  deletion_protection             = var.deletion_protection
  authentication_mode             = var.authentication_mode
  cluster_upgrade_policy          = var.upgrade_policy
  control_plane_subnet_ids        = var.control_plane_subnet_ids
  subnet_ids                      = var.subnet_ids
  cluster_endpoint_private_access = var.endpoint_private_access
  cluster_endpoint_public_access  = var.endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.endpoint_public_access_cidrs
  cluster_ip_family               = var.ip_family
  cluster_service_ipv4_cidr       = var.service_ipv4_cidr
  cluster_encryption_config       = var.encryption_config
  cluster_tags                    = var.cluster_tags

  # Access Entries
  access_entries                            = var.access_entries
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  # KMS Key Configuration
  create_kms_key      = var.create_kms_key
  kms_key_description = var.kms_key_description

  # CloudWatch Log Group
  create_cloudwatch_log_group             = var.create_cloudwatch_log_group
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days

  # Cluster Security Group
  create_cluster_security_group           = var.create_security_group
  cluster_security_group_id               = var.security_group_id
  vpc_id                                  = var.vpc_id
  cluster_security_group_name             = var.security_group_name
  cluster_security_group_use_name_prefix  = var.security_group_use_name_prefix
  cluster_security_group_description     = var.security_group_description
  cluster_security_group_tags            = var.security_group_tags

  # Node Security Group & Karpenter Discovery Tagging
  create_node_security_group                   = var.create_node_security_group
  node_security_group_id                       = var.node_security_group_id
  node_security_group_name                     = var.node_security_group_name
  node_security_group_use_name_prefix           = var.node_security_group_use_name_prefix
  node_security_group_description              = var.node_security_group_description
  node_security_group_enable_recommended_rules = var.node_security_group_enable_recommended_rules
  node_security_group_tags = merge(var.node_security_group_tags, {
    "karpenter.sh/discovery" = var.name
  })

  # IRSA / OIDC Provider
  enable_irsa                     = var.enable_irsa
  openid_connect_audiences        = var.openid_connect_audiences
  include_oidc_root_ca_thumbprint = var.include_oidc_root_ca_thumbprint
  custom_oidc_thumbprints         = var.custom_oidc_thumbprints

  # Cluster IAM Role
  create_iam_role               = var.create_iam_role
  iam_role_arn                  = var.iam_role_arn
  iam_role_name                 = var.iam_role_name
  iam_role_use_name_prefix      = var.iam_role_use_name_prefix
  iam_role_path                 = var.iam_role_path
  iam_role_description          = var.iam_role_description
  iam_role_permissions_boundary = var.iam_role_permissions_boundary
  cluster_encryption_policy_name        = var.encryption_policy_name
  cluster_encryption_policy_description = var.encryption_policy_description

  # EKS Addons & Node Defaults
  cluster_addons = var.addons

  eks_managed_node_group_defaults = {
    instance_types        = [var.instance_type]
    block_device_mappings = var.block_device_mappings
  }

  # Bootstrap Node Group (Hosts Karpenter Controller)
  eks_managed_node_groups = {
    bootstrap = {
      instance_types = [var.instance_type]
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      capacity_type  = "ON_DEMAND"
      labels = {
        "karpenter.sh/controller" = "true"
      }
    }
  }
}