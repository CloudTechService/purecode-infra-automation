# modules/lambda_function_stop/outputs.tf

output "lambda_function_arn" {
  description = "ARN of the stop scheduler Lambda function"
  value       = aws_lambda_function.stop_scheduler.arn
}

output "lambda_function_name" {
  description = "Name of the stop scheduler Lambda function"
  value       = aws_lambda_function.stop_scheduler.function_name
}

output "lambda_function_invoke_arn" {
  description = "Invoke ARN of the stop scheduler Lambda function"
  value       = aws_lambda_function.stop_scheduler.invoke_arn
}

output "iam_role_arn" {
  description = "ARN of the IAM role for the stop scheduler Lambda function"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "iam_role_name" {
  description = "Name of the IAM role for the stop scheduler Lambda function"
  value       = aws_iam_role.lambda_execution_role.name
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for the stop scheduler Lambda function"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for the stop scheduler Lambda function"
  value       = aws_cloudwatch_log_group.lambda_logs.arn
}

output "schedule_rule_name" {
  description = "Name of the CloudWatch Event Rule for the stop schedule"
  value       = var.schedule_enabled ? aws_cloudwatch_event_rule.schedule[0].name : null
}

output "schedule_rule_arn" {
  description = "ARN of the CloudWatch Event Rule for the stop schedule"
  value       = var.schedule_enabled ? aws_cloudwatch_event_rule.schedule[0].arn : null
}

output "schedule_enabled" {
  description = "Whether the stop schedule is enabled"
  value       = var.schedule_enabled
}

output "schedule_expression" {
  description = "The schedule expression for the stop scheduler"
  value       = var.schedule_expression
}