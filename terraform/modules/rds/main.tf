module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  create_db_instance = var.create_db_instance
  identifier         = var.identifier
  instance_use_identifier_prefix = var.instance_use_identifier_prefix

  # Engine & Hardware Configuration
  engine               = var.engine
  engine_version       = var.engine_version
  engine_lifecycle_support = var.engine_lifecycle_support
  family               = var.family
  major_engine_version = var.major_engine_version
  instance_class       = var.instance_class

  # Storage Configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_throughput    = var.storage_throughput
  iops                  = var.iops
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id
  dedicated_log_volume  = var.dedicated_log_volume

  # Database Credentials & Management
  db_name  = var.db_name
  username = var.username
  port     = var.port

  password_wo                    = var.password_wo
  password_wo_version            = var.password_wo_version
  manage_master_user_password    = var.manage_master_user_password
  master_user_secret_kms_key_id = var.master_user_secret_kms_key_id
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  # Networking & Security
  vpc_security_group_ids = var.vpc_security_group_ids
  availability_zone      = var.availability_zone
  multi_az               = var.multi_az
  publicly_accessible    = var.publicly_accessible
  network_type           = var.network_type
  ca_cert_identifier     = var.ca_cert_identifier

  # Subnet Group
  create_db_subnet_group          = var.create_db_subnet_group
  db_subnet_group_name            = var.db_subnet_group_name
  db_subnet_group_use_name_prefix = var.db_subnet_group_use_name_prefix
  db_subnet_group_description     = var.db_subnet_group_description
  subnet_ids                      = var.subnet_ids

  # Parameter Group
  create_db_parameter_group       = var.create_db_parameter_group
  parameter_group_name            = var.parameter_group_name
  parameter_group_use_name_prefix = var.parameter_group_use_name_prefix
  parameter_group_description     = var.parameter_group_description
  parameters                      = var.parameters
  parameter_group_skip_destroy    = var.parameter_group_skip_destroy

  # Backups & Maintenance
  skip_final_snapshot               = var.skip_final_snapshot
  snapshot_identifier               = var.snapshot_identifier
  copy_tags_to_snapshot             = var.copy_tags_to_snapshot
  final_snapshot_identifier_prefix = var.final_snapshot_identifier_prefix
  delete_automated_backups          = var.delete_automated_backups
  backup_retention_period           = var.backup_retention_period
  backup_window                     = var.backup_window
  maintenance_window                = var.maintenance_window
  allow_major_version_upgrade       = var.allow_major_version_upgrade
  auto_minor_version_upgrade        = var.auto_minor_version_upgrade
  apply_immediately                 = var.apply_immediately
  deletion_protection               = var.deletion_protection
  blue_green_update                 = var.blue_green_update

  # Monitoring & Insights
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_role_arn
  create_monitoring_role                = var.create_monitoring_role
  monitoring_role_name                  = var.monitoring_role_name
  monitoring_role_use_name_prefix       = var.monitoring_role_use_name_prefix
  monitoring_role_description          = var.monitoring_role_description
  monitoring_role_permissions_boundary = var.monitoring_role_permissions_boundary
  
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  performance_insights_kms_key_id       = var.performance_insights_kms_key_id
  database_insights_mode                = var.database_insights_mode

  # CloudWatch Log Export
  enabled_cloudwatch_logs_exports         = var.enabled_cloudwatch_logs_exports
  create_cloudwatch_log_group             = var.create_cloudwatch_log_group
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_kms_key_id        = var.cloudwatch_log_group_kms_key_id
  cloudwatch_log_group_skip_destroy       = var.cloudwatch_log_group_skip_destroy
  cloudwatch_log_group_class              = var.cloudwatch_log_group_class

  # Role Associations & Tagging
  db_instance_role_associations = var.db_instance_role_associations

  tags                    = var.tags
  db_instance_tags        = var.db_instance_tags
  db_option_group_tags    = var.db_option_group_tags
  db_parameter_group_tags = var.db_parameter_group_tags
  db_subnet_group_tags    = var.db_subnet_group_tags
  cloudwatch_log_group_tags = var.cloudwatch_log_group_tags

  region = var.region
}