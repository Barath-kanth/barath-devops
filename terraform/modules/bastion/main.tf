terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_iam_policy_document" "bastion_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bastion" {
  name_prefix        = "${var.name}-bastion-"
  assume_role_policy = data.aws_iam_policy_document.bastion_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion" {
  name_prefix = "${var.name}-bastion-"
  role        = aws_iam_role.bastion.name
  tags        = var.tags
}

resource "aws_security_group" "bastion" {
  name_prefix = "${var.name}-bastion-"
  description = "SSM bastion - no inbound SSH; egress to VPC/API only"
  vpc_id      = var.vpc_id
  tags = merge(var.tags, {
    Name = "${var.name}-bastion"
  })

  # No inbound from internet. Operators use SSM Session Manager.
  egress {
    description = "HTTPS to VPC endpoints / EKS API / package mirrors via NAT"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP (yum mirrors via NAT if needed)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "DNS"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Allow bastion → EKS API (control plane ENIs use cluster SG)
resource "aws_security_group_rule" "eks_api_from_bastion" {
  # Use != "" so count is known at plan time (null from a destroyed EKS SG breaks destroy).
  count = var.cluster_security_group_id != null && var.cluster_security_group_id != "" ? 1 : 0

  type                     = "ingress"
  description              = "Bastion to EKS API"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = var.cluster_security_group_id
  source_security_group_id = aws_security_group.bastion.id
}

locals {
  ssm_services = toset(["ssm", "ssmmessages", "ec2messages"])
}

resource "aws_security_group" "vpc_endpoints" {
  count = var.create_ssm_vpc_endpoints ? 1 : 0

  name_prefix = "${var.name}-vpce-"
  description = "Interface VPC endpoints for SSM"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-vpce-ssm" })

  ingress {
    description     = "HTTPS from bastion"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # Nodes/bastion in VPC may also need SSM
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_endpoint" "ssm" {
  for_each = var.create_ssm_vpc_endpoints ? local.ssm_services : toset([])

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
  tags = merge(var.tags, {
    Name = "${var.name}-vpce-${each.key}"
  })
}

resource "aws_instance" "bastion" {
  ami                         = coalesce(var.ami_id, data.aws_ami.al2023.id)
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  iam_instance_profile        = aws_iam_instance_profile.bastion.name
  associate_public_ip_address = false
  monitoring                  = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(var.tags, {
    Name = "${var.name}-bastion"
    Role = "bastion"
  })

  lifecycle {
    ignore_changes = [ami]
  }
}
