variable "lambda_iam_role_name" {}
variable "lambda_function_name" {}
variable "lambda_function_source" {}
variable "lambda_timeout" {
  default = "15"
}
variable "lambda_runtime" { 
  default = "python3.8"
}
variable "lambda_layers" {
  description = "Lambda layers for the function"
  default = []
}
variable "lambda_variables" {
  default = {}
}

variable "lambda_handler" { 
  description = "Handler for function"
  default = "function.lambda_handler" 
}
