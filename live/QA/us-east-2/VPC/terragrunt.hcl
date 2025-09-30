# include "root" {
#   path = find_in_parent_folders()
# }

# terraform {
#   source = "../../../..//modules/VPC"
# }

# inputs = {
#   region          = "us-east-2"
#   env             = "qa"
#   vpc_cidr        = "10.71.0.0/16"
#   private_subnets = ["10.71.1.0/24","10.71.2.0/24","10.71.3.0/24"]
#   public_subnets  = ["10.71.4.0/24","10.71.5.0/24","10.71.6.0/24"]
#   azs             = ["us-east-2a","us-east-2b","us-east-2c"]
#   tags            = {
#     Project = "Purecode-QA"
#     Owner   = "QA Team"
#   }
# }


include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../..//modules/VPC"
}

inputs = {
  region = "us-east-2"
  env    = "qa"

  # VPC Configuration
  vpc_cidr        = "10.71.0.0/16"
  private_subnets = ["10.71.1.0/24", "10.71.2.0/24", "10.71.3.0/24"]
  public_subnets  = ["10.71.4.0/24", "10.71.5.0/24", "10.71.6.0/24"]
  azs             = ["us-east-2a", "us-east-2b", "us-east-2c"]

  # Optional: Database subnets
  # database_subnets = ["10.71.7.0/24", "10.71.8.0/24", "10.71.9.0/24"]
  # create_database_subnet_group = true

  # NAT Gateway Configuration
  # Single NAT Gateway (cost-effective for QA)
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  # For Production/HA, use:
  # single_nat_gateway     = false
  # one_nat_gateway_per_az = true

  # DNS Configuration
  enable_dns_hostnames = true
  enable_dns_support   = true

  # VPC Flow Logs (optional - useful for debugging)
  # enable_flow_log            = true
  # flow_log_retention_in_days = 7

  # VPC Endpoints (optional - can reduce data transfer costs)
  # enable_s3_endpoint       = true
  # enable_dynamodb_endpoint = true

  # Tags
  tags = {
    Project     = "Purecode-QA"
    Owner       = "QA Team"
    Environment = "qa"
    ManagedBy   = "Terragrunt"
  }

  # # Additional subnet-specific tags
  # public_subnet_tags = {
  #   "kubernetes.io/role/elb" = "1"  # If using EKS
  # }

  # private_subnet_tags = {
  #   "kubernetes.io/role/internal-elb" = "1"  # If using EKS
  # }
}