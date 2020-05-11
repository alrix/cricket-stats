module "s3_bucket" {
  source = "../terraform_modules/s3_bucket"
  bucket_name = var.name
}

module "etl" {
  source = "../terraform_modules/lambda"
  lambda_iam_role_name = "lambda_${var.name}_etl"
  lambda_function_name = "${var.name}-etl"
  lambda_function_source = "../functions/etl"
  lambda_layers = [ module.lambda_layer.lambda_layer_arn ]
  lambda_variables = {
    S3_BUCKET = module.s3_bucket.bucket_id
  }
	lambda_timeout = 30
}
module "api" {
  source = "../terraform_modules/lambda"
  lambda_iam_role_name = "lambda_${var.name}_api"
  lambda_function_name = "${var.name}-api"
  lambda_function_source = "../functions/api"
  lambda_layers = [ module.lambda_layer.lambda_layer_arn ]
  lambda_variables = {
    S3_BUCKET = module.s3_bucket.bucket_id
  }
}
  
module "lambda_layer" {
  source = "../terraform_modules/lambda_layer"
  lambda_layer_name = var.name
}

