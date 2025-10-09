# terragrunt.hcl (root)

# -----------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# -----------------------------------------------------------------------------
locals {
  common_vars  = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  
  name_prefix    = local.common_vars.locals.name_prefix
  account_name   = local.account_vars.locals.account_name
  account_id     = local.account_vars.locals.account_id
  default_region = local.common_vars.locals.default_region
  aws_region     = local.region_vars.locals.aws_region
  profile        = local.account_vars.locals.profile
}

remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    encrypt        = true
    bucket         = "${local.name_prefix}-${local.account_name}-${local.aws_region}-terragrunt-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    profile        = "${local.profile}"
  }
}


# -----------------------------------------------------------------------------
# GENERATED PROVIDER BLOCK
# -----------------------------------------------------------------------------
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = "${local.aws_region}"
  profile = "${local.profile}"
  
  # Only these AWS Account IDs may be operated on by this template
  allowed_account_ids = ["${local.account_id}"]
  
  default_tags {
    tags = {
      Environment = "${local.account_name}"
      Project     = "QA-Server-Scheduler"
      ManagedBy   = "Terragrunt"
      Region      = "${local.aws_region}"
    }
  }
}
EOF
}

# -----------------------------------------------------------------------------
# TERRAFORM CONFIGURATION
# -----------------------------------------------------------------------------
terraform {
  extra_arguments "retry_lock" {
    commands  = get_terraform_commands_that_need_locking()
    arguments = ["-lock-timeout=20m"]
  }

  extra_arguments "parallelism" {
    commands  = ["apply", "plan", "destroy"]
    arguments = ["-parallelism=10"]
  }
}

# -----------------------------------------------------------------------------
# GLOBAL PARAMETERS
# -----------------------------------------------------------------------------
inputs = {
  # Set commonly used inputs globally to keep child terragrunt.hcl files DRY
  aws_account_id = local.account_id
  aws_region     = local.aws_region
  name_prefix    = local.name_prefix
  account_name   = local.account_name
  profile        = local.profile
}