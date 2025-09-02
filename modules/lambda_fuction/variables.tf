# modules/lambda_function/variables.tf

variable "aws_profile" {
  description = "AWS profile to use"
  type        = string
  default     = "default"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "function_name_prefix" {
  description = "Prefix for Lambda function names"
  type        = string
}

variable "start_function_name" {
  description = "Name of the start Lambda function"
  type        = string
}

variable "stop_function_name" {
  description = "Name of the stop Lambda function"
  type        = string
}

variable "start_description" {
  description = "Description of the start Lambda function"
  type        = string
  default     = "Start QA Server instances"
}

variable "stop_description" {
  description = "Description of the stop Lambda function"
  type        = string
  default     = "Stop QA Server instances"
}

variable "runtime" {
  description = "Runtime for the Lambda function"
  type        = string
  default     = "python3.9"
}

variable "handler" {
  description = "Handler for the Lambda function"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "timeout" {
  description = "Timeout for the Lambda function in seconds"
  type        = number
  default     = 300
}

variable "memory_size" {
  description = "Memory size for the Lambda function in MB"
  type        = number
  default     = 256
}

variable "start_source_path" {
  description = "Path to the start Lambda function source code"
  type        = string
}

variable "stop_source_path" {
  description = "Path to the stop Lambda function source code"
  type        = string
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "instance_ids" {
  description = "Comma-separated list of EC2 instance IDs to manage"
  type        = string
}

variable "start_schedule" {
  description = "Cron expression for starting instances"
  type        = string
  default     = "cron(0 8 * * ? *)"  # 8 AM UTC daily
}

variable "stop_schedule" {
  description = "Cron expression for stopping instances"
  type        = string
  default     = "cron(0 1 * * ? *)"  # 1 AM UTC daily
}

variable "schedules_enabled" {
  description = "Whether to enable the schedules"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}