module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "~> 3.0"

  create_distribution = var.create
  tags                = var.tags

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

  origin                 = coalesce(var.origin, {})
  origin_group           = coalesce(var.origin_group, {})
  default_cache_behavior = var.default_cache_behavior

  logging_config        = coalesce(var.logging_config, {})
  geo_restriction       = var.restrictions.geo_restriction
  custom_error_response = coalesce(var.custom_error_response, {})

  viewer_certificate = var.viewer_certificate

  create_origin_access_control = length(var.origin_access_control) > 0
  origin_access_control        = var.origin_access_control
}
