# Security Group
resource "aws_security_group" "ec2_sg" {
  name        = "${var.env}-ec2-sg"
  description = "Security group for ${var.env} EC2 instances"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.http_allowed_cidrs
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.http_allowed_cidrs
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.env}-ec2-sg"
  })
}


# Determine public IP per subnet
locals {
  # Filter out subnets with 0 instances
  filtered_subnets = { for k, v in var.subnets : k => v if v > 0 }

  # Expand each subnet into individual instance keys
  ec2_instances_map = merge([
    for subnet_id, num in local.filtered_subnets : {
      for i in range(num) : "${subnet_id}-${i+1}" => subnet_id
    }
  ]...)
}

# EC2 Instances using official module
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7"

  for_each = local.ec2_instances_map

  name = "${var.env}-ec2-${each.key}"

  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  monitoring                  = var.enable_detailed_monitoring
  associate_public_ip_address = contains(var.public_subnet_ids, each.value)

  subnet_id              = each.value
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  # Only add cpu_options if values are provided
  cpu_options = var.cpu_core_count != null || var.cpu_threads_per_core != null ? {
    core_count       = var.cpu_core_count
    threads_per_core = var.cpu_threads_per_core
  } : null

  tags = merge(var.tags, {
    Name        = "${var.env}-ec2-${each.key}"
    Environment = var.env
  })
}
