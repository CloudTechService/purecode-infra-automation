# modules/lambda_function/main.tf

# Data source for Lambda function zip files
data "archive_file" "start_lambda_zip" {
  type        = "zip"
  source_file = var.start_source_path
  output_path = "${path.module}/start_lambda_function.zip"
}

data "archive_file" "stop_lambda_zip" {
  type        = "zip"
  source_file = var.stop_source_path
  output_path = "${path.module}/stop_lambda_function.zip"
}

# Read the Lambda EC2 policy from JSON file
data "local_file" "lambda_ec2_policy" {
  filename = "${path.module}/policies/lambda_ec2_policy.json"
}

# IAM Trust Policy for Lambda
data "aws_iam_policy_document" "lambda_trust_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Create IAM Role for Lambda function
resource "aws_iam_role" "lambda_execution_role" {
  name               = "server-schedular-lambda-execution-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy.json
  description        = "IAM role for Lambda functions to manage EC2 instances"

  tags = var.tags
}

# Create IAM Policy from JSON file
resource "aws_iam_policy" "lambda_ec2_policy" {
  name        = "server-schedular-lambda-ec2-policy"
  description = "Policy for Lambda functions to manage EC2 instances"
  policy      = data.local_file.lambda_ec2_policy.content

  tags = var.tags
}

# Attach the custom EC2 policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_ec2_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_ec2_policy.arn
}

# # Attach AWS managed policy for basic Lambda execution
# resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
#   role       = aws_iam_role.lambda_execution_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }

# CloudWatch Log Groups for Lambda functions
resource "aws_cloudwatch_log_group" "start_lambda_logs" {
  name              = "/aws/lambda/${var.start_function_name}"
  retention_in_days = 14
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "stop_lambda_logs" {
  name              = "/aws/lambda/${var.stop_function_name}"
  retention_in_days = 14
  tags              = var.tags
}

# Start Lambda function
resource "aws_lambda_function" "start_scheduler" {
  filename         = data.archive_file.start_lambda_zip.output_path
  function_name    = var.start_function_name
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = var.handler
  source_code_hash = data.archive_file.start_lambda_zip.output_base64sha256
  runtime         = var.runtime
  timeout         = var.timeout
  memory_size     = var.memory_size
  description     = var.start_description

  environment {
    variables = merge(
      var.environment_variables,
      {
        INSTANCE_IDS = var.instance_ids
      }
    )
  }

  depends_on = [
    aws_cloudwatch_log_group.start_lambda_logs,
    aws_iam_role_policy_attachment.lambda_ec2_policy_attachment,
    aws_iam_role_policy_attachment.lambda_basic_execution,
  ]

  tags = var.tags
}

# Stop Lambda function
resource "aws_lambda_function" "stop_scheduler" {
  filename         = data.archive_file.stop_lambda_zip.output_path
  function_name    = var.stop_function_name
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = var.handler
  source_code_hash = data.archive_file.stop_lambda_zip.output_base64sha256
  runtime         = var.runtime
  timeout         = var.timeout
  memory_size     = var.memory_size
  description     = var.stop_description

  environment {
    variables = merge(
      var.environment_variables,
      {
        INSTANCE_IDS = var.instance_ids
      }
    )
  }

  depends_on = [
    aws_cloudwatch_log_group.stop_lambda_logs,
    aws_iam_role_policy_attachment.lambda_ec2_policy_attachment,
    aws_iam_role_policy_attachment.lambda_basic_execution,
  ]

  tags = var.tags
}

# CloudWatch Event Rule for starting instances
resource "aws_cloudwatch_event_rule" "start_schedule" {
  name                = "server-schedular-start"
  description         = "Start QA servers for ${var.environment} environment"
  schedule_expression = var.start_schedule
  state              = var.schedules_enabled ? "ENABLED" : "DISABLED"

  tags = var.tags
}

# CloudWatch Event Rule for stopping instances
resource "aws_cloudwatch_event_rule" "stop_schedule" {
  name                = "server-schedular-stop"
  description         = "Stop QA servers for ${var.environment} environment"
  schedule_expression = var.stop_schedule
  state              = var.schedules_enabled ? "ENABLED" : "DISABLED"

  tags = var.tags
}

# CloudWatch Event Target for start function
resource "aws_cloudwatch_event_target" "start_target" {
  rule      = aws_cloudwatch_event_rule.start_schedule.name
  target_id = "start-target"
  arn       = aws_lambda_function.start_scheduler.arn
}

# CloudWatch Event Target for stop function
resource "aws_cloudwatch_event_target" "stop_target" {
  rule      = aws_cloudwatch_event_rule.stop_schedule.name
  target_id = "stop-target"
  arn       = aws_lambda_function.stop_scheduler.arn
}

# Lambda permissions for CloudWatch Events
resource "aws_lambda_permission" "allow_cloudwatch_start" {
  statement_id  = "AllowExecutionFromCloudWatch-start"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_schedule.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_stop" {
  statement_id  = "AllowExecutionFromCloudWatch-stop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_schedule.arn
}