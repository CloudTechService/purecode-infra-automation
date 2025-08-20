# live/purecode/account.hcl
# Account-specific configuration for purecode environment

locals {
  # Load accounts from JSON (find in parent folders)
  accounts_config = jsondecode(file(find_in_parent_folders("accounts.json")))
  
  # Account identification
  account_name = "qa"
  account_id   = local.accounts_config.accounts[local.account_name].account_id
  profile      = local.accounts_config.accounts[local.account_name].profile
  
  # Lambda function configuration
  lambda_timeout     = 300
  lambda_memory_size = 256
  log_level          = "INFO"
  
  # Schedule configuration (using cron expressions)
  start_schedule    = "cron(0 8 * * ? *)"   # 8 AM UTC daily
  stop_schedule     = "cron(0 1 * * ? *)"   # 1 AM UTC daily
  schedules_enabled = true
  
  # TODO: Update with actual EC2 instance IDs for this account
  instance_ids = [
    "i-1234567890abcdef0",
    "i-0987654321fedcba0"
  ]
  
  # Account-specific tags
  account_tags = {
    AccountName = local.account_name
    AccountId   = local.account_id
    Department  = "QA"
  }
}