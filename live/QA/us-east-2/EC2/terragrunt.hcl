include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/EC2"
}

dependency "vpc" {
  config_path = "../VPC"  # Make sure this path points to your VPC Terragrunt stack
}

inputs = {
  vpc_id             = dependency.vpc.outputs.vpc_id
  region             = "us-east-2"
  env                = "qa"
 subnets = {
    # Public Subnets
    (dependency.vpc.outputs.public_subnets[0])  = 1  # 10.71.4.0/24 - 1 instance
    (dependency.vpc.outputs.public_subnets[1])  = 0  # 10.71.5.0/24 - 0 instances
    (dependency.vpc.outputs.public_subnets[2])  = 0  # 10.71.6.0/24 - 0 instances
    
    # Private Subnets  
    (dependency.vpc.outputs.private_subnets[0]) = 0  # 10.71.1.0/24 - 0 instances
    (dependency.vpc.outputs.private_subnets[1]) = 0  # 10.71.2.0/24 - 0 instances
    (dependency.vpc.outputs.private_subnets[2]) = 0  # 10.71.3.0/24 - 0 instances
  }
  public_subnet_ids  = dependency.vpc.outputs.public_subnets
  ami_id             = "ami-0cfde0ea8edd312d4"
  instance_type      = "t3.micro"
  key_name           = "qa-keypair"
  ssh_allowed_cidrs  = ["10.71.4.0/24"]
  http_allowed_cidrs = ["0.0.0.0/0"]
  enable_detailed_monitoring = false  # Set to true for production
  tags = {
    Project = "Purecode-QA"
    Owner   = "QA Team"
  }
}

# include "root" {
#   path = find_in_parent_folders()
# }

# # Use Terraform Registry module directly
# terraform {
#   source = "tfr:///terraform-aws-modules/ec2-instance/aws//.?version=5.7.0"
# }

# dependency "vpc" {
#   config_path = "../VPC"
# }

# locals {
#   region = "us-east-2"
#   env    = "qa"
  
#   # Define subnets configuration
#   subnets_config = {
#     # Public Subnets
#     (dependency.vpc.outputs.public_subnets[0])  = 1  # 10.71.4.0/24 - 1 instance
#     (dependency.vpc.outputs.public_subnets[1])  = 0  # 10.71.5.0/24 - 0 instances
#     (dependency.vpc.outputs.public_subnets[2])  = 0  # 10.71.6.0/24 - 0 instances
    
#     # Private Subnets  
#     (dependency.vpc.outputs.private_subnets[0]) = 0  # 10.71.1.0/24 - 0 instances
#     (dependency.vpc.outputs.private_subnets[1]) = 0  # 10.71.2.0/24 - 0 instances
#     (dependency.vpc.outputs.private_subnets[2]) = 0  # 10.71.3.0/24 - 0 instances
#   }
  
#   # Filter out subnets with 0 instances
#   filtered_subnets = { for k, v in local.subnets_config : k => v if v > 0 }
  
#   # Expand each subnet into individual instance keys
#   ec2_instances_map = merge([
#     for subnet_id, num in local.filtered_subnets : {
#       for i in range(num) : "${subnet_id}-${i+1}" => {
#         subnet_id = subnet_id
#         is_public = contains(dependency.vpc.outputs.public_subnets, subnet_id)
#       }
#     }
#   ]...)
# }

# # Override the module's versions.tf to prevent duplicate required_providers
# generate "versions_override" {
#   path      = "versions.tf"
#   if_exists = "overwrite"
#   contents  = ""
# }

# # Generate the security group (this is custom to your needs, not part of EC2 module)
# generate "security_group" {
#   path      = "security_group.tf"
#   if_exists = "overwrite"
#   contents  = <<EOF
# resource "aws_security_group" "ec2_sg" {
#   name        = "${local.env}-ec2-sg"
#   description = "Security group for ${local.env} EC2 instances"
#   vpc_id      = "${dependency.vpc.outputs.vpc_id}"

#   ingress {
#     description = "SSH"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["10.71.4.0/24"]
#   }

#   ingress {
#     description = "HTTP"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     description = "HTTPS"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     description = "All outbound"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name        = "${local.env}-ec2-sg"
#     Project     = "Purecode-QA"
#     Owner       = "QA Team"
#     Environment = "${local.env}"
#     ManagedBy   = "Terragrunt"
#   }
# }
# EOF
# }

# # Generate wrapper to call the module multiple times
# generate "ec2_wrapper" {
#   path      = "ec2_wrapper.tf"
#   if_exists = "overwrite"
#   contents  = <<EOF
# module "ec2_instance" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   version = "~> 5.7"

#   for_each = {
# %{for key, config in local.ec2_instances_map~}
#     "${key}" = {
#       subnet_id = "${config.subnet_id}"
#       is_public = ${config.is_public}
#     }
# %{endfor~}
#   }

#   name = "${local.env}-ec2-$${each.key}"

#   ami                         = "ami-0cfde0ea8edd312d4"
#   instance_type               = "t3.micro"
#   key_name                    = "qa-keypair"
#   monitoring                  = false
#   associate_public_ip_address = each.value.is_public

#   subnet_id              = each.value.subnet_id
#   vpc_security_group_ids = [aws_security_group.ec2_sg.id]

#   tags = {
#     Name        = "${local.env}-ec2-$${each.key}"
#     Environment = "${local.env}"
#     Project     = "Purecode-QA"
#     Owner       = "QA Team"
#     ManagedBy   = "Terragrunt"
#   }
# }
# EOF
# }

# # Generate outputs
# generate "outputs" {
#   path      = "outputs.tf"
#   if_exists = "overwrite"
#   contents  = <<EOF
# output "ec2_instance_ids" {
#   description = "List of EC2 instance IDs"
#   value       = [for inst in module.ec2_instance : inst.id]
# }

# output "ec2_public_ips" {
#   description = "List of public IP addresses"
#   value       = [for inst in module.ec2_instance : inst.public_ip]
# }

# output "ec2_private_ips" {
#   description = "List of private IP addresses"
#   value       = [for inst in module.ec2_instance : inst.private_ip]
# }

# output "security_group_id" {
#   description = "Security group ID"
#   value       = aws_security_group.ec2_sg.id
# }

# output "ec2_details" {
#   description = "Detailed EC2 instance information"
#   value = {
#     for key, inst in module.ec2_instance : key => {
#       id         = inst.id
#       private_ip = inst.private_ip
#       public_ip  = inst.public_ip
#       subnet_id  = inst.subnet_id
#     }
#   }
# }
# EOF
# }

# inputs = {}


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
#   subnets = {
#     # Public Subnets
#     dependency.vpc.outputs.public_subnets[0]  = 1  # 10.71.4.0/24 - 1 instance
#     dependency.vpc.outputs.public_subnets[1]  = 0  # 10.71.5.0/24 - 0 instances
#     dependency.vpc.outputs.public_subnets[2]  = 0  # 10.71.6.0/24 - 0 instances
    
#     # Private Subnets  
#     dependency.vpc.outputs.private_subnets[0] = 0  # 10.71.1.0/24 - 0 instances
#     dependency.vpc.outputs.private_subnets[1] = 0  # 10.71.2.0/24 - 0 instances
#     dependency.vpc.outputs.private_subnets[2] = 0  # 10.71.3.0/24 - 0 instances
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