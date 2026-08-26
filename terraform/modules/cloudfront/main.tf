module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "~> 3.0"

  create = var.create
  tags   = var.tags

  # Distribution Core Configuration
  aliases             = var.aliases
  comment             = var.comment
  default_root_object = var.default_root_object
  enabled             = var.enabled
  http_version        = var.http_version
  is_ipv6_enabled     = var.is_ipv6_enabled
  price_class         = var.price_class
  retain_on_delete    = var.retain_on_delete
  staging             = var.staging
  wait_for_deployment = var.wait_for_deployment
  web_acl_id          = var.web_acl_id

  # Origins & Behaviors
  origin                 = var.origin
  origin_group           = var.origin_group
  default_cache_behavior = var.default_cache_behavior

  # Logging, Restrictions & Custom Error Responses
  logging_config        = var.logging_config
  restrictions          = var.restrictions
  custom_error_response = var.custom_error_response

  # Viewer Certificate
  viewer_certificate = var.viewer_certificate

  # Additional Resources / Policies
  create_origin_access_control = length(var.origin_access_control) > 0
  origin_access_control        = var.origin_access_control

  cache_policies            = var.cache_policies
  origin_request_policies   = var.origin_request_policies
  response_headers_policies = var.response_headers_policies
}