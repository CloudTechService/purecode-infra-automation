# modules/ec2/variables.tf

variable "vpc_id" {
  description = "VPC ID where EC2 instances will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "environment" {
  description = "Environment name (e.g., qa, dev, prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "servers" {
  description = "Map of server configurations"
  type = map(object({
    subnet_type   = string
    subnet_index  = number
    ami           = string
    instance_type = string
    key_name      = string
    role          = string
    root_volume = object({
      size                  = number
      type                  = string
      iops                  = optional(number)
      throughput            = optional(number)
      encrypted             = bool
      delete_on_termination = bool
    })
  }))
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}