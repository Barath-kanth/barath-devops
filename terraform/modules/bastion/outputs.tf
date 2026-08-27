output "instance_id" {
  description = "Bastion EC2 instance ID (SSM target)"
  value       = aws_instance.bastion.id
}

output "security_group_id" {
  value = aws_security_group.bastion.id
}

output "private_ip" {
  value = aws_instance.bastion.private_ip
}

output "iam_role_arn" {
  value = aws_iam_role.bastion.arn
}
