# live/QA/us-east-2/EC2/terragrunt.hcl

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules//ec2-instance"
}

locals {
  region = "us-east-2"
  env    = "qa"
}

inputs = {
  name          = "Jenkis Server"
  instance_type = "t3.micro"
  key_name      = "qa-keypair"
  monitoring    = true
  subnet_id     = "subnet-0f5d7f800a61ce166"
  
  # VPC ID for the subnet
  vpc_id = "vpc-0f1f05c1122134138"
   
  tags = {
    Project     = "Purecode-QA"
    Owner       = "QA Team"
    Environment = local.env
    ManagedBy   = "Terragrunt"
    Terraform   = "true"
  }
}