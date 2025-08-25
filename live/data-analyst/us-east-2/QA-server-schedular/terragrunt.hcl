# live/data-analyst/us-east-2/QA-server-schedular/terragrunt.hcl

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules//lambda_fuction"
}


# Read configuration from parent folders
locals {
  common_vars  = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  
  # Load accounts from JSON
  accounts_config = jsondecode(file(find_in_parent_folders("accounts.json")))
  
  # Extract commonly used values
  account_name = local.account_vars.locals.account_name
  account_id   = local.accounts_config.accounts[local.account_name].account_id
  aws_region   = local.region_vars.locals.aws_region
  
  # Merge tags from all levels
  merged_tags = merge(
    local.common_vars.locals.common_tags,
    local.account_vars.locals.account_tags,
    local.region_vars.locals.region_tags,
    {
      Service = "QA-Server-Scheduler"
    }
  )
}

inputs = {
  # Environment configuration
  environment = local.account_name
  aws_region  = local.aws_region
  aws_profile = local.accounts_config.accounts[local.account_name].profile

  # Existing IAM role from accounts.json
  existing_role_name = local.accounts_config.accounts[local.account_name].role_name

  # Lambda function configuration
  function_name_prefix = "${local.common_vars.locals.name_prefix}-${local.account_name}"
  start_function_name  = "${local.common_vars.locals.name_prefix}-${local.account_name}-start"
  stop_function_name   = "${local.common_vars.locals.name_prefix}-${local.account_name}-stop"
  start_description    = "Start QA Server instances for ${local.accounts_config.accounts[local.account_name].description}"
  stop_description     = "Stop QA Server instances for ${local.accounts_config.accounts[local.account_name].description}"

  # Lambda runtime configuration from account-specific settings
  runtime     = local.common_vars.locals.lambda_runtime
  handler     = local.common_vars.locals.lambda_handler
  timeout     = local.account_vars.locals.lambda_timeout
  memory_size = local.account_vars.locals.lambda_memory_size

  # Lambda source code paths
  start_source_path = "${get_terragrunt_dir()}/start_lambda_function.py"
  stop_source_path  = "${get_terragrunt_dir()}/stop_lambda_function.py"

  # Environment variables for Lambda
  environment_variables = {
    ENVIRONMENT = local.account_name
    LOG_LEVEL   = local.account_vars.locals.log_level
    REGION      = local.aws_region
    ACCOUNT_ID  = local.account_id
  }

  # Lambda function configuration
  lambda_timeout     = 300
  lambda_memory_size = 256
  log_level          = "INFO"
  
  # Schedule configuration (using cron expressions)
  start_schedule = "cron(15 2 ? * MON-FRI *)"    # 2:15 AM UTC Mon-Fri (8 AM NPT Mon-Fri)
  stop_schedule  = "cron(15 19 ? * MON-FRI *)"   # 7:15 PM UTC Mon-Fri (1 AM NPT next day)
  schedules_enabled = true
  
  # TODO: Update with actual EC2 instance IDs for this account
  instance_ids = [
    "i-1234567890abcdef0",
    "i-0987654321fedcba0"
  ]

  # Instance IDs to manage (TODO: Update with actual instance IDs)
  instance_ids = local.account_vars.locals.instance_ids

  # Schedule configuration
  start_schedule     = local.account_vars.locals.start_schedule
  stop_schedule      = local.account_vars.locals.stop_schedule
  schedules_enabled  = local.account_vars.locals.schedules_enabled

  # Use merged tags
  tags = local.merged_tags
}