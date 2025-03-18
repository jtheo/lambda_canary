variable "name" {
  type    = string
  default = "mattmar1"
}

locals {
  role = "lambda-${var.name}"
}

provider "aws" {}

resource "aws_iam_role" "lambda_role" {
  name = local.role

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com",
      },
    }],
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = local.role
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ],
      Effect   = "Allow",
      Resource = "arn:aws:logs:*:*:*",
    }],
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "mattmar1" {
  function_name = var.name
  handler       = "bootstrap"
  runtime       = "provided.al2023"
  role          = aws_iam_role.lambda_role.arn
  filename      = "${path.module}/dist/bootstrap.zip"
}
resource "aws_lambda_function_url" "mattmar1" {
  function_name      = aws_lambda_function.mattmar1.function_name
  qualifier          = "live"
  authorization_type = "NONE"
}

resource "aws_lambda_alias" "mattmar1" {
  name          = "live"
  description   = "live lambda with routing options"
  function_name = aws_lambda_function.mattmar1.arn
  # function_version = data.aws_lambda_function.mattmar1.version
  function_version = aws_lambda_function.mattmar1.version
}

resource "local_file" "lambda_url" {
  content  = aws_lambda_function_url.mattmar1.function_url
  filename = "${path.module}/lambda_url.txt"
}
