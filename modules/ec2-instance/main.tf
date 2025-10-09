# modules/ec2/main.tf

# Security Group for Public EC2 Instances
resource "aws_security_group" "public_sg" {
  name        = "${var.environment}-public-ec2-sg"
  description = "Security group for public EC2 instances"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-public-ec2-sg"
    }
  )
}

# Security Group for Private EC2 Instances
resource "aws_security_group" "private_sg" {
  name        = "${var.environment}-private-ec2-sg"
  description = "Security group for private EC2 instances"
  vpc_id      = var.vpc_id

  # SSH access from public subnet
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_sg.id]
    description     = "SSH access from public instances"
  }

  # Application ports
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.public_sg.id]
    description     = "Application access from public instances"
  }

  # Application ports
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.public_sg.id]
    description     = "Application access from public instances"
  }

  # Database port (MySQL/Aurora)
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    description = "MySQL access from VPC"
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-private-ec2-sg"
    }
  )
}

# Get VPC CIDR block
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# Local values for subnet selection
locals {
  public_servers = {
    for name, config in var.servers : name => config
    if config.subnet_type == "public"
  }
  
  private_servers = {
    for name, config in var.servers : name => config
    if config.subnet_type == "private"
  }
}

# Public EC2 Instances
resource "aws_instance" "public_servers" {
  for_each = local.public_servers

  ami                         = each.value.ami
  instance_type               = each.value.instance_type
  key_name                    = each.value.key_name
  subnet_id                   = var.public_subnet_ids[each.value.subnet_index]
  vpc_security_group_ids      = [aws_security_group.public_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = each.value.root_volume.size
    volume_type           = each.value.root_volume.type
    iops                  = each.value.root_volume.iops
    throughput            = each.value.root_volume.throughput
    encrypted             = each.value.root_volume.encrypted
    delete_on_termination = each.value.root_volume.delete_on_termination
  }

  # root_block_device {
  #   volume_size           = 300
  #   volume_type           = "gp3"
  #   encrypted             = true
  #   delete_on_termination = true
  # }

  # user_data = <<-EOF
  #             #!/bin/bash
  #             yum update -y
  #             yum install -y httpd
  #             systemctl start httpd
  #             systemctl enable httpd
  #             echo "<h1>${each.key} - ${var.environment}</h1>" > /var/www/html/index.html
  #             EOF

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-${each.key}"
      Role = each.value.role
    }
  )
}

# Private EC2 Instances
resource "aws_instance" "private_servers" {
  for_each = local.private_servers

  ami                    = each.value.ami
  instance_type          = each.value.instance_type
  key_name               = each.value.key_name
  subnet_id              = var.private_subnet_ids[each.value.subnet_index]
  vpc_security_group_ids = [aws_security_group.private_sg.id]

  root_block_device {
    volume_size           = each.value.root_volume.size
    volume_type           = each.value.root_volume.type
    iops                  = each.value.root_volume.iops
    throughput            = each.value.root_volume.throughput
    encrypted             = each.value.root_volume.encrypted
    delete_on_termination = each.value.root_volume.delete_on_termination
  }

  # root_block_device {
  #   volume_size           = 20
  #   volume_type           = "gp3"
  #   encrypted             = true
  #   delete_on_termination = true
  # }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              EOF

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-${each.key}"
      Role = each.value.role
    }
  )
}