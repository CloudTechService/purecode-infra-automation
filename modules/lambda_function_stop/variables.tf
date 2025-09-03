# modules/lambda_function_stop/variables.tf

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = "Lambda function to stop EC2 instances"
}

variable "source_path" {
  description = "Path to the Lambda function source file"
  type        = string
}

variable "handler" {
  description = "Lambda function handler"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "runtime" {
  description = "Lambda function runtime"
  type        = string
  default     = "python3.9"
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 300
}

variable "memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 256
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_ids" {
  description = "Comma-separated string of EC2 instance IDs to stop"
  type        = string
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "schedule_enabled" {
  description = "Whether to enable the CloudWatch schedule"
  type        = bool
  default     = true
}

variable "schedule_expression" {
  description = "CloudWatch Events schedule expression"
  type        = string
  default     = "cron(0 18 ? * MON-FRI *)"
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}