# modules/lambda_function_start/main.tf

# Data source for Lambda function zip file
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = var.source_path
  output_path = "${path.module}/start_lambda_function.zip"
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
  name               = "${var.function_name}-${data.aws_region.current.name}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy.json
  description        = "IAM role for Start Lambda function to manage EC2 instances"

  tags = var.tags
}

# Create IAM Policy from JSON file
resource "aws_iam_policy" "lambda_ec2_policy" {
  name        = "${var.function_name}-ec2-policy"
  description = "Policy for Start Lambda function to manage EC2 instances"
  policy      = data.local_file.lambda_ec2_policy.content

  tags = var.tags
}

# Attach the custom EC2 policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_ec2_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_ec2_policy.arn
}

# Attach AWS managed policy for basic Lambda execution
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# CloudWatch Log Group for Lambda function
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# Start Lambda function
resource "aws_lambda_function" "start_scheduler" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.function_name
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = var.handler
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = var.runtime
  timeout         = var.timeout
  memory_size     = var.memory_size
  description     = var.description

  environment {
    variables = merge(
      var.environment_variables,
      {
        INSTANCE_IDS = var.instance_ids
        ACTION       = "start"
      }
    )
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs,
    aws_iam_role_policy_attachment.lambda_ec2_policy_attachment,
    aws_iam_role_policy_attachment.lambda_basic_execution,
  ]

  tags = var.tags
}

# CloudWatch Event Rule for starting instances
resource "aws_cloudwatch_event_rule" "schedule" {
  count               = var.schedule_enabled ? 1 : 0
  name                = "${var.function_name}-schedule"
  description         = "Start QA servers for ${var.environment} environment"
  schedule_expression = var.schedule_expression
  state              = "ENABLED"

  tags = var.tags
}

# CloudWatch Event Target for start function
resource "aws_cloudwatch_event_target" "target" {
  count     = var.schedule_enabled ? 1 : 0
  rule      = aws_cloudwatch_event_rule.schedule[0].name
  target_id = "${var.function_name}-target"
  arn       = aws_lambda_function.start_scheduler.arn
}

# Lambda permissions for CloudWatch Events
resource "aws_lambda_permission" "allow_cloudwatch" {
  count         = var.schedule_enabled ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule[0].arn
}