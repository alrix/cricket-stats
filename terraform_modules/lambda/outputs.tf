output "lambda_iam_role_arn" {
  value = aws_iam_role.lambda.arn
}
output "lambda_iam_role_name" {
  value = aws_iam_role.lambda.name
}

output "lambda_arn" {
  value = aws_lambda_function.lambda.arn
}

output "lambda_invoke_arn" {
  value = aws_lambda_function.lambda.invoke_arn
}

output "lambda_function_name" {
  value = aws_lambda_function.lambda.function_name
}
