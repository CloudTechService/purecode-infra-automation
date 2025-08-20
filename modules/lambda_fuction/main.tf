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

# Use existing IAM role
data "aws_iam_role" "existing_lambda_role" {
  name = var.existing_role_name
}

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
  role            = data.aws_iam_role.existing_lambda_role.arn
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
  ]

  tags = var.tags
}

# Stop Lambda function
resource "aws_lambda_function" "stop_scheduler" {
  filename         = data.archive_file.stop_lambda_zip.output_path
  function_name    = var.stop_function_name
  role            = data.aws_iam_role.existing_lambda_role.arn
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
  ]

  tags = var.tags
}

# CloudWatch Event Rule for starting instances
resource "aws_cloudwatch_event_rule" "start_schedule" {
  name                = "${var.function_name_prefix}-start"
  description         = "Start QA servers for ${var.environment} environment"
  schedule_expression = var.start_schedule
  state              = var.schedules_enabled ? "ENABLED" : "DISABLED"

  tags = var.tags
}

# CloudWatch Event Rule for stopping instances
resource "aws_cloudwatch_event_rule" "stop_schedule" {
  name                = "${var.function_name_prefix}-stop"
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