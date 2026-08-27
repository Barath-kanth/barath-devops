variable "name" {
  description = "Name prefix (e.g. aws-devops-dev)"
  type        = string
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for bastion + SSM VPC endpoints"
  type        = list(string)
}

variable "cluster_security_group_id" {
  description = "EKS cluster security group — allows bastion HTTPS to API"
  type        = string
  default     = null
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ami_id" {
  type    = string
  default = null
}

variable "create_ssm_vpc_endpoints" {
  description = "Create interface endpoints so private bastion can use SSM without public IP"
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
