# Distribution Core Outputs
output "cloudfront_distribution_id" {
  description = "The identifier for the CloudFront distribution"
  value       = module.cloudfront.cloudfront_distribution_id
}

output "cloudfront_distribution_arn" {
  description = "The ARN (Amazon Resource Name) for the CloudFront distribution"
  value       = module.cloudfront.cloudfront_distribution_arn
}

output "cloudfront_distribution_domain_name" {
  description = "The domain name corresponding to the distribution"
  value       = module.cloudfront.cloudfront_distribution_domain_name
}

output "cloudfront_distribution_hosted_zone_id" {
  description = "The CloudFront Route 53 zone ID that can be used to route an Alias resource record set"
  value       = module.cloudfront.cloudfront_distribution_hosted_zone_id
}

output "cloudfront_distribution_status" {
  description = "The current status of the distribution (e.g. Deployed, InProgress)"
  value       = module.cloudfront.cloudfront_distribution_status
}

output "cloudfront_distribution_etag" {
  description = "The current version of the distribution's information"
  value       = module.cloudfront.cloudfront_distribution_etag
}

output "cloudfront_distribution_caller_reference" {
  description = "Internal value used to track unique distribution creation requests"
  value       = module.cloudfront.cloudfront_distribution_caller_reference
}

# Origin Access Control (OAC)
output "cloudfront_origin_access_controls" {
  description = "Map of CloudFront Origin Access Controls created"
  value       = module.cloudfront.cloudfront_origin_access_controls
}

# Managed/Custom Policies
output "cloudfront_cache_policies" {
  description = "Map of CloudFront cache policies created"
  value       = module.cloudfront.cloudfront_cache_policies
}

output "cloudfront_origin_request_policies" {
  description = "Map of CloudFront origin request policies created"
  value       = module.cloudfront.cloudfront_origin_request_policies
}

output "cloudfront_response_headers_policies" {
  description = "Map of CloudFront response headers policies created"
  value       = module.cloudfront.cloudfront_response_headers_policies
}