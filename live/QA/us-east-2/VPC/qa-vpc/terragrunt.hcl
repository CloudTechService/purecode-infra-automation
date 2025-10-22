# live/QA.us-east-2/VPC/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

# Point directly to Terraform Registry module - NO local module needed
terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws//.?version=5.1.2"
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
  # Basic VPC Configuration
  name = "${local.env}-vpc"
  cidr = "10.71.0.0/16"

  # Subnets across 3 AZs
  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets = ["10.71.1.0/24", "10.71.2.0/24", "10.71.3.0/24"]
  public_subnets  = ["10.71.4.0/24", "10.71.5.0/24", "10.71.6.0/24"]

  # NAT Gateway Configuration
  # Single NAT Gateway for cost savings in QA
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  # DNS Configuration
  enable_dns_hostnames = true
  enable_dns_support   = true

  # # VPC Flow Logs (optional)
  # enable_flow_log                      = false
  # create_flow_log_cloudwatch_iam_role  = false
  # create_flow_log_cloudwatch_log_group = false
  # flow_log_retention_in_days           = 7

  # Main VPC Tags
  tags = {
    Name        = "${local.env}-vpc"
    Project     = "Purecode-QA"
    Owner       = "QA Team"
    Environment = local.env
    ManagedBy   = "Terragrunt"
    Terraform   = "true"
  }

  # VPC Tags
  vpc_tags = {
    Name = "${local.env}-vpc"
  }

  # Public Subnet Tags
  public_subnet_tags = {
    Name = "${local.env}-public-subnet"
    Type = "Public"
  }

  # Private Subnet Tags
  private_subnet_tags = {
    Name = "${local.env}-private-subnet"
    Type = "Private"
  }

  # Route Table Tags
  public_route_table_tags = {
    Name = "${local.env}-public-rt"
  }

  private_route_table_tags = {
    Name = "${local.env}-private-rt"
  }

  # Internet Gateway Tags
  igw_tags = {
    Name = "${local.env}-igw"
  }

  # NAT Gateway Tags
  nat_gateway_tags = {
    Name = "${local.env}-nat"
  }

  nat_eip_tags = {
    Name = "${local.env}-nat-eip"
  }
}