include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../..//modules/VPC"
}

inputs = {
  region          = "us-east-2"
  env             = "qa"
  vpc_cidr        = "10.71.0.0/16"
  private_subnets = ["10.71.1.0/24","10.71.2.0/24","10.71.3.0/24"]
  public_subnets  = ["10.71.4.0/24","10.71.5.0/24","10.71.6.0/24"]
  azs             = ["us-east-2a","us-east-2b","us-east-2c"]
  tags            = {
    Project = "Purecode-QA"
    Owner   = "QA Team"
  }
}
