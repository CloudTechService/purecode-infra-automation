# live/sandbox/us-east-2/QA-server-schedular/terragrunt.hcl

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
  
  # Individual schedule control - MODIFY THESE AS NEEDED
  start_enabled = true   # Set to false to disable start schedule
  stop_enabled  = false  # Set to false to disable stop schedule

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
  # Environment setup
  environment = local.account_name

  # IAM Role from accounts.json
  existing_role_name = local.accounts_config.accounts[local.account_name].role_name

  # Lambda function config
  function_name_prefix = "server-schedular-${local.account_name}"
  start_function_name  = "server-schedular-${local.account_name}-start"
  stop_function_name   = "server-schedular-${local.account_name}-stop"
  start_description    = "Start QA Server instances for ${local.accounts_config.accounts[local.account_name].description}"
  stop_description     = "Stop QA Server instances for ${local.accounts_config.accounts[local.account_name].description}"

  # Runtime config (fixed defaults)
  runtime     = local.common_vars.locals.lambda_runtime
  handler     = local.common_vars.locals.lambda_handler

  # Lambda source code
  start_source_path = "${get_terragrunt_dir()}/start_lambda_function.py"
  stop_source_path  = "${get_terragrunt_dir()}/stop_lambda_function.py"

  # Environment variables
  environment_variables = {
    ENVIRONMENT = local.account_name
    LOG_LEVEL   = try(local.account_vars.locals.log_level, "INFO")
    REGION      = local.aws_region
    ACCOUNT_ID  = local.account_id
  }

  # Lambda-specific overrides
  lambda_timeout     = 300
  lambda_memory_size = 256
  log_level          = "INFO"

  # Schedule configuration
  start_schedule     = "cron(15 2 ? * MON-FRI *)"   # 2:15 AM UTC
  stop_schedule      = "cron(15 19 ? * MON-FRI *)"  # 7:15 PM UTC
  start_enabled     = local.start_enabled          # Individual control for start schedule
  stop_enabled      = local.stop_enabled           # Individual control for stop schedule

  # Instance IDs
  instance_ids = try(local.account_vars.locals.instance_ids, [
    "i-1234567890abcdef0",
    "i-0987654321fedcba0"
  ])

  # Tags
  tags = local.merged_tags
}
