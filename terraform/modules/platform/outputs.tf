output "vpc_id" {
  value = module.network.vpc_id
}

output "private_subnets" {
  value = module.network.private_subnets
}

output "database_subnets" {
  value = module.network.database_subnets
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "eks_node_security_group_id" {
  value = module.eks.node_security_group_id
}

output "rds_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "rds_master_user_secret_arn" {
  value     = module.rds.db_master_user_secret_arn
  sensitive = true
}

output "static_bucket_id" {
  value = module.s3.s3_bucket_id
}

output "cloudfront_domain_name" {
  value = module.cloudfront.cloudfront_distribution_domain_name
}

output "cloudfront_distribution_id" {
  value = module.cloudfront.cloudfront_distribution_id
}

output "bastion_instance_id" {
  description = "SSM target for EKS API port-forward"
  value       = try(module.bastion[0].instance_id, null)
}

output "bastion_private_ip" {
  value = try(module.bastion[0].private_ip, null)
}

output "eks_cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

output "external_secrets_role_arn" {
  description = "IRSA role for External Secrets Operator"
  value       = aws_iam_role.external_secrets.arn
}

output "bookshelf_db_secret_name" {
  description = "Secrets Manager key for ESO ExternalSecret (stable per environment)"
  value       = aws_secretsmanager_secret.bookshelf_db.name
}

output "bookshelf_db_secret_arn" {
  description = "ARN of the bookshelf application DB secret in Secrets Manager"
  value       = aws_secretsmanager_secret.bookshelf_db.arn
  sensitive   = true
}
