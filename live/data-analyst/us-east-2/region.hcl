# live/data-analyst/us-east-2/region.hcl
# Region-specific configuration for us-east-2

locals {
  aws_region = "us-east-2"
  
  # Region-specific tags
  region_tags = {
    Region = local.aws_region
  }
}