# live/QA/us-east-2/EC2/terragrunt.hcl

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///terraform-aws-modules/ec2-instance/aws?version=6.1.1"
}

locals {
  region = "us-east-2"
  env    = "qa"
}

# Override the module's versions.tf to prevent duplicate required_providers
generate "versions_override" {
  path      = "versions.tf"
  if_exists = "overwrite"
  contents  = ""  # Empty file - root provider.tf already has required_providers
}

inputs = {
  name = "Jenkins-Server"

  # AMI - Update with your desired AMI for us-east-2
  # Or use SSM parameter to get latest Amazon Linux 2023
  ami = "ami-0c55b159cbfafe1f0"  # Update this
  
  instance_type               = "t3.micro"
  key_name                    = "qa-keypair"
  monitoring                  = true
  subnet_id                   = "subnet-0f5d7f800a61ce166"
  associate_public_ip_address = true

  # Create and configure security group
  create_security_group      = true
  security_group_name        = "jenkins-server-sg"
  security_group_description = "Security group for Jenkins Server"
  vpc_id                     = "vpc-0f1f05c1122134138"

  # Security group ingress rules
  security_group_ingress_rules = {
    ssh = {
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "SSH access"
    }
    jenkins = {
      from_port   = 8080
      to_port     = 8080
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Jenkins web interface"
    }
    https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "HTTPS access"
    }
  }

  # Security group egress rules
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow all outbound traffic"
    }
  }

  # Root block device configuration (v6.x uses object, not list)
  root_block_device = {
    type                  = "gp3"
    size                  = 30
    delete_on_termination = true
    encrypted             = true
  }

  # Additional EBS volumes (optional)
  # Note: In v6.x, ebs_block_device has been replaced with ebs_volumes
  ebs_volumes = {}

  # Tags
  tags = {
    Name        = "Jenkins-Server"
    Project     = "Purecode-QA"
    Owner       = "QA Team"
    Environment = local.env
    ManagedBy   = "Terragrunt"
    Terraform   = "true"
  }
}