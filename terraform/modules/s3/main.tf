module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  create_bucket = var.create_bucket

  bucket        = var.bucket
  bucket_prefix = var.bucket_prefix

  attach_policy                            = var.attach_policy
  attach_public_policy                     = var.attach_public_policy
  attach_access_log_delivery_policy        = var.attach_access_log_delivery_policy
  attach_deny_insecure_transport_policy    = var.attach_deny_insecure_transport_policy
  attach_require_latest_tls_policy         = var.attach_require_latest_tls_policy
  attach_deny_incorrect_encryption_headers = var.attach_deny_incorrect_encryption_headers
  attach_deny_incorrect_kms_key_sse        = var.attach_deny_incorrect_kms_key_sse
  attach_deny_unencrypted_object_uploads   = var.attach_deny_unencrypted_object_uploads
  allowed_kms_key_arn                      = var.allowed_kms_key_arn

  access_log_delivery_policy_source_buckets       = var.access_log_delivery_policy_source_buckets
  access_log_delivery_policy_source_accounts      = var.access_log_delivery_policy_source_accounts
  access_log_delivery_policy_source_organizations = var.access_log_delivery_policy_source_organizations
  lb_log_delivery_policy_source_organizations     = var.lb_log_delivery_policy_source_organizations

  website                              = var.website
  cors_rule                            = var.cors_rule
  versioning                           = var.versioning
  logging                              = var.logging
  server_side_encryption_configuration = var.server_side_encryption_configuration
  intelligent_tiering                  = var.intelligent_tiering

  lifecycle_rule                         = var.lifecycle_rule
  transition_default_minimum_object_size = var.transition_default_minimum_object_size

  object_lock_enabled       = var.object_lock_enabled
  object_lock_configuration = var.object_lock_configuration

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets

  control_object_ownership = var.control_object_ownership
  object_ownership         = var.object_ownership
}
