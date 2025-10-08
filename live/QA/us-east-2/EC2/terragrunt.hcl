# include "root" {
#   path = find_in_parent_folders()
# }

# terraform {
#   source = "../../../../modules/EC2"
# }

# dependency "vpc" {
#   config_path = "../VPC"  # Make sure this path points to your VPC Terragrunt stack
# }

# inputs = {
#   vpc_id             = dependency.vpc.outputs.vpc_id
#   region             = "us-east-2"
#   env                = "qa"
#  subnets = {
#     # Public Subnets
#     (dependency.vpc.outputs.public_subnets[0])  = 0  # 10.71.4.0/24 - 1 instance
#     (dependency.vpc.outputs.public_subnets[1])  = 0  # 10.71.5.0/24 - 0 instances
#     (dependency.vpc.outputs.public_subnets[2])  = 0  # 10.71.6.0/24 - 0 instances
    
#     # Private Subnets  
#     (dependency.vpc.outputs.private_subnets[0]) = 0  # 10.71.1.0/24 - 0 instances
#     (dependency.vpc.outputs.private_subnets[1]) = 0  # 10.71.2.0/24 - 0 instances
#     (dependency.vpc.outputs.private_subnets[2]) = 0  # 10.71.3.0/24 - 0 instances
#   }
#   public_subnet_ids  = dependency.vpc.outputs.public_subnets
#   ami_id             = "ami-0cfde0ea8edd312d4"
#   instance_type      = "t3.micro"
#   key_name           = "qa-keypair"
#   ssh_allowed_cidrs  = ["10.71.4.0/24"]
#   http_allowed_cidrs = ["0.0.0.0/0"]
#   enable_detailed_monitoring = false  # Set to true for production
#   tags = {
#     Project = "Purecode-QA"
#     Owner   = "QA Team"
#   }
# }

# live/QA/us-east-2/EC2/terragrunt.hcl

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///terraform-aws-modules/ec2-instance/aws//.?version=5.6.0"
}


# Dependency on VPC to get subnet IDs
dependency "vpc" {
  config_path = "../VPC"
}

locals {
  region = "us-east-2"
  env    = "qa"
  
  # Define your EC2 instances configuration
  instances = {
    "web-server-1" = {
      ami                         = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2023
      instance_type               = "t3.micro"
      subnet_index                = 0  # First public subnet (us-east-2a)
      subnet_type                 = "public"
      associate_public_ip_address = true
      root_volume_size            = 20
      monitoring                  = false
      user_data                   = <<-EOF
        #!/bin/bash
        yum update -y
        yum install -y httpd
        systemctl start httpd
        systemctl enable httpd
        echo "<h1>Web Server 1 - QA</h1>" > /var/www/html/index.html
      EOF
    }
  }
}

# Override the module's versions.tf
generate "versions_override" {
  path      = "versions.tf"
  if_exists = "overwrite"
  contents  = ""
}

# Generate wrapper to create multiple instances using for_each
generate "main" {
  path      = "main.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    module "ec2_instances" {
      source  = "terraform-aws-modules/ec2-instance/aws"
      version = "5.6.0"
      
      for_each = var.instances
      
      name = "$${var.env}-$${each.key}"
      
      ami                    = each.value.ami
      instance_type          = each.value.instance_type
      key_name              = var.key_name
      monitoring            = each.value.monitoring
      
      vpc_security_group_ids      = var.vpc_security_group_ids
      subnet_id                   = each.value.subnet_id
      associate_public_ip_address = each.value.associate_public_ip_address
      
      user_data_base64 = base64encode(each.value.user_data)

      root_block_device = [
        {
          volume_type = "gp3"
          volume_size = each.value.root_volume_size
          encrypted   = true
          tags = {
            Name = "$${var.env}-$${each.key}-root-volume"
          }
        }
      ]
      
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 1
      }
      
      tags = merge(
        var.common_tags,
        {
          Name       = "$${var.env}-$${each.key}"
          SubnetType = each.value.subnet_type
          SubnetAZ   = each.value.subnet_az
        }
      )
      
      volume_tags = {
        Name        = "$${var.env}-$${each.key}-volume"
        Environment = var.env
      }
    }
  EOF
}

generate "variables" {
  path      = "variables.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    variable "instances" {
      description = "Map of EC2 instances to create"
      type = map(object({
        ami                         = string
        instance_type               = string
        subnet_id                   = string
        subnet_type                 = string
        subnet_az                   = string
        associate_public_ip_address = bool
        user_data                   = string
        root_volume_size            = number
        monitoring                  = bool
      }))
    }
    
    variable "vpc_security_group_ids" {
      description = "List of security group IDs"
      type        = list(string)
    }
    
    variable "key_name" {
      description = "SSH key name"
      type        = string
    }
    
    variable "common_tags" {
      description = "Common tags for all instances"
      type        = map(string)
    }
    
    variable "env" {
      description = "Environment name"
      type        = string
    }
  EOF
}

generate "outputs" {
  path      = "outputs.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    output "instance_ids" {
      description = "IDs of EC2 instances"
      value       = { for k, v in module.ec2_instances : k => v.id }
    }
    
    output "instance_public_ips" {
      description = "Public IPs of EC2 instances"
      value       = { for k, v in module.ec2_instances : k => v.public_ip }
    }
    
    output "instance_private_ips" {
      description = "Private IPs of EC2 instances"
      value       = { for k, v in module.ec2_instances : k => v.private_ip }
    }
    
    output "instance_arns" {
      description = "ARNs of EC2 instances"
      value       = { for k, v in module.ec2_instances : k => v.arn }
    }
    
    output "instance_availability_zones" {
      description = "Availability zones of EC2 instances"
      value       = { for k, v in module.ec2_instances : k => v.availability_zone }
    }
  EOF
}

inputs = {
  env = local.env
  
  # Transform instances config to include actual subnet_id from VPC dependency
  instances = {
    for name, config in local.instances : name => merge(config, {
      subnet_id = config.subnet_type == "private" ? dependency.vpc.outputs.private_subnets[config.subnet_index] : dependency.vpc.outputs.public_subnets[config.subnet_index]
      subnet_az = "${local.region}${substr("abc", config.subnet_index, 1)}"
    })
  }
  
  # SSH Key Name (make sure this exists in AWS)
  key_name = "${local.env}-keypair"
  
  # Security Groups (add your security group IDs here)
  vpc_security_group_ids = []
  
  # Common tags for all instances
  common_tags = {
    Project     = "Purecode-QA"
    Owner       = "QA Team"
    Environment = local.env
    ManagedBy   = "Terragrunt"
    Terraform   = "true"
  }
}