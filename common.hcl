# common.hcl
# -----------------------------------------------------------------------------
# COMMON CONFIGURATION
# Shared across all accounts and regions
# -----------------------------------------------------------------------------

locals {
  # Load account configuration from external JSON file
  accounts_config = jsondecode(file("${get_parent_terragrunt_dir()}/accounts.json"))  
  
  # TODO: Enter a unique name prefix to set for all resources created in your accounts
  name_prefix = "qa-scheduler"
  
  # TODO: Enter the default AWS region, the same as where the terraform state S3 bucket is currently provisioned
  default_region = local.accounts_config.default_region
  
  # Project-specific configurations
  project_name = "QA-Server-Scheduler"
  
  # Common resource configurations
  lambda_runtime = "python3.9"
  lambda_handler = "lambda_function.lambda_handler"
  
  # Common tags applied to all resources
  common_tags = {
    Project     = "QA-Server-Scheduler"
    ManagedBy   = "Terragrunt"
    Owner       = "DevOps-Team"
    Environment = "multi-account"
  }
  
  # Extract accounts from JSON for easy access
  accounts = local.accounts_config.accounts
  
  # Source profile for cross-account access
  source_profile = local.accounts_config.source_profile
}