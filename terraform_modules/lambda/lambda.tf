# Define the location of the zip archive for the function
locals {
  function_archive = "../output/${var.lambda_function_name}.zip"
}

# Create an archive file for the function
data "archive_file" "lambda_zip" {
    type        = "zip"
    source_dir  = var.lambda_function_source
    output_path = local.function_archive
}

# Create the lambda function
resource "aws_lambda_function" "lambda" {
  filename      = local.function_archive
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda.arn
  handler       = var.lambda_handler
  layers        = var.lambda_layers
  source_code_hash = filebase64sha256(local.function_archive)

  timeout = var.lambda_timeout
  runtime = var.lambda_runtime

  environment {
    variables = var.lambda_variables
  }
}

