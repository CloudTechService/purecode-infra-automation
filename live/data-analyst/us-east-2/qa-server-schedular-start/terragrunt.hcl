# live/purecode/ap-south-1/qa-server-schedular-start/terragrunt.hcl

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules//lambda_function_start"
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
      Service = "QA-Server-Start-Scheduler"
    }
  )
}

inputs = {
  # Function configuration
  function_name = "${local.common_vars.locals.name_prefix}-${local.account_name}-start-function"
  description   = "Start QA Server instances for ${local.accounts_config.accounts[local.account_name].description}"
  environment   = local.account_name
  
  # Lambda configuration
  source_path = "${get_terragrunt_dir()}/start_lambda_function.py"
  runtime     = local.common_vars.locals.lambda_runtime
  handler     = "start_lambda_function.lambda_handler"
  timeout     = 300
  memory_size = 256
  
  # Schedule configuration
  schedule_enabled    = true  # Set to false to disable this scheduler
  schedule_expression = "cron(15 2 ? * MON-FRI *)"  # 2:15 AM UTC
  log_retention_days  = 14
  
  # Instance IDs
  instance_ids = join(",", try(local.account_vars.locals.instance_ids, [
    "i-07a59db3128835cfb"
  ]))

  # Environment variables
  environment_variables = {
    ENVIRONMENT = local.account_name
    LOG_LEVEL   = "INFO"
    REGION      = local.aws_region
    ACCOUNT_ID  = local.account_id
  }

  # Tags
  tags = local.merged_tags
}