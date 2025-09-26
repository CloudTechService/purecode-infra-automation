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
    (dependency.vpc.outputs.public_subnet_ids[0])  = 1  # 10.71.4.0/24 - 1 instance
    (dependency.vpc.outputs.public_subnet_ids[1])  = 0  # 10.71.5.0/24 - 0 instances
    (dependency.vpc.outputs.public_subnet_ids[2])  = 0  # 10.71.6.0/24 - 0 instances
    
    # Private Subnets  
    (dependency.vpc.outputs.private_subnet_ids[0]) = 0  # 10.71.1.0/24 - 0 instances
    (dependency.vpc.outputs.private_subnet_ids[1]) = 0  # 10.71.2.0/24 - 0 instances
    (dependency.vpc.outputs.private_subnet_ids[2]) = 0  # 10.71.3.0/24 - 0 instances
  }
  public_subnet_ids  = dependency.vpc.outputs.public_subnet_ids
  ami_id             = "ami-0cfde0ea8edd312d4"
  instance_type      = "t3.micro"
  key_name           = "qa-keypair"
  ssh_allowed_cidrs  = ["10.71.4.0/24"]
  http_allowed_cidrs = ["0.0.0.0/0"]
  tags = {
    Project = "Purecode-QA"
    Owner   = "QA Team"
  }
}

