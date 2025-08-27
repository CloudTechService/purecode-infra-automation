# live/purecode/account.hcl
# Account-specific configuration for purecode environment

locals {
  # Load accounts from JSON (find in parent folders)
  accounts_config = jsondecode(file(find_in_parent_folders("accounts.json")))
  
  # Account identification
  account_name = "purecode"
  account_id   = local.accounts_config.accounts[local.account_name].account_id
  profile      = local.accounts_config.accounts[local.account_name].profile
  
  # Account-specific tags
  account_tags = {
    AccountName = local.account_name
    AccountId   = local.account_id
    Department  = "Development"
  }
}
