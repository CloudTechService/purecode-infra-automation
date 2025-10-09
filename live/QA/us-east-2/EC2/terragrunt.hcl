# live/QA/us-east-2/EC2/terragrunt.hcl

include "root" {
  path = find_in_parent_folders()
}

# Dependency on VPC
dependency "vpc" {
  config_path = "../VPC"
}

terraform {
  source = "../../../../modules/ec2-instance"
}

locals {
  region = "us-east-2"
  env    = "qa"
}

inputs = {
  # VPC Configuration
  vpc_id             = dependency.vpc.outputs.vpc_id
  public_subnet_ids  = dependency.vpc.outputs.public_subnets
  private_subnet_ids = dependency.vpc.outputs.private_subnets
  
  # Environment
  environment = local.env
  region      = local.region
  
  # Multiple Servers Configuration
  servers = {
    # Public Servers - Different subnets for HA
    Jenkins-Server = {
      subnet_type   = "public"
      subnet_index  = 0  # us-east-2a
      ami           = "ami-0cfde0ea8edd312d4"
      instance_type = "t3a.medium"
      key_name      = "qa-keypair"
      role          = "Jenkins Server"

      # Root volume configuration
      root_volume = {
        size                  = 300
        type                  = "gp3"
        iops                  = 3000      # Optional, for gp3/io1/io2
        throughput            = 125       # Optional, for gp3 only
        encrypted             = true
        delete_on_termination = true
    }}
    
    # web_server_2 = {
    #   subnet_type   = "public"
    #   subnet_index  = 1  # us-east-2b
    #   ami           = "ami-0cfde0ea8edd312d4"
    #   instance_type = "t3.small"
    #   key_name      = "qa-keypair"
    #   role          = "Web Server"
    # }
    
    # # Private Servers - Different subnets for HA
    # app_server_1 = {
    #   subnet_type   = "private"
    #   subnet_index  = 0  # us-east-2a
    #   ami           = "ami-0cfde0ea8edd312d4"
    #   instance_type = "t3.micro"
    #   key_name      = "qa-keypair"
    #   role          = "Application Server"
    # }
    
    # db_server_1 = {
    #   subnet_type   = "private"
    #   subnet_index  = 1  # us-east-2b
    #   ami           = "ami-0cfde0ea8edd312d4"
    #   instance_type = "t3.medium"
    #   key_name      = "qa-keypair"
    #   role          = "Database Server"
    # }
  }
  
  # Tags
  tags = {
    Project     = "Purecode-QA"
    Owner       = "QA Team"
    Environment = local.env
    ManagedBy   = "Terragrunt"
    Terraform   = "true"
  }
}