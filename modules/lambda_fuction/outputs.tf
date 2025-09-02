# modules/lambda_function/outputs.tf

output "start_lambda_function_arn" {
  description = "ARN of the start Lambda function"
  value       = aws_lambda_function.start_scheduler.arn
}

output "stop_lambda_function_arn" {
  description = "ARN of the stop Lambda function"
  value       = aws_lambda_function.stop_scheduler.arn
}

output "start_lambda_function_name" {
  description = "Name of the start Lambda function"
  value       = aws_lambda_function.start_scheduler.function_name
}

output "stop_lambda_function_name" {
  description = "Name of the stop Lambda function"
  value       = aws_lambda_function.stop_scheduler.function_name
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "lambda_role_name" {
  description = "Name of the Lambda IAM role"
  value       = aws_iam_role.lambda_execution_role.name
}

output "lambda_policy_arn" {
  description = "ARN of the Lambda IAM policy"
  value       = aws_iam_policy.lambda_ec2_policy.arn
}

output "start_schedule_rule_name" {
  description = "Name of the start schedule CloudWatch Event Rule"
  value       = aws_cloudwatch_event_rule.start_schedule.name
}

output "stop_schedule_rule_name" {
  description = "Name of the stop schedule CloudWatch Event Rule"
  value       = aws_cloudwatch_event_rule.stop_schedule.name
}

output "start_schedule_rule_arn" {
  description = "ARN of the start schedule CloudWatch Event Rule"
  value       = aws_cloudwatch_event_rule.start_schedule.arn
}

output "stop_schedule_rule_arn" {
  description = "ARN of the stop schedule CloudWatch Event Rule"
  value       = aws_cloudwatch_event_rule.stop_schedule.arn
}