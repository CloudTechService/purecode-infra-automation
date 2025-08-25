# live/demo/account.hcl
# Account-specific configuration for demo environment

locals {
  # Load accounts from JSON (find in parent folders)
  accounts_config = jsondecode(file(find_in_parent_folders("accounts.json")))
  
  # Account identification
  account_name = "demo"
  account_id   = local.accounts_config.accounts[local.account_name].account_id
  profile      = local.accounts_config.accounts[local.account_name].profile
  
  # Lambda function configuration
  lambda_timeout     = 300
  lambda_memory_size = 256
  log_level          = "INFO"
  
}
