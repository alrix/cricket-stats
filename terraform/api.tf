# Add policy to IAM role to allow ETL Lambda Function S3 bucket access
resource "aws_iam_role_policy_attachment" "api_s3_bucket_access" {
  role       = module.api.lambda_iam_role_name
  policy_arn = aws_iam_policy.api_s3_bucket_access.arn
}

resource "aws_iam_policy" "api_s3_bucket_access" {
  name        = "${module.api.lambda_iam_role_name}_s3_bucket_access"
  path        = "/"
  description = "S3 Bucket Access for Lambda Function"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListAllMyBuckets",
      "Resource": "arn:aws:s3:::*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:ListBucketMultipartUploads"
      ],
      "Resource": "arn:aws:s3:::${module.s3_bucket.bucket_id}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::${module.s3_bucket.bucket_id}/*"
    }
  ]
}
EOF
}

# Setup the api gateway
resource "aws_api_gateway_rest_api" "api" {
  name        = var.name
}

resource "aws_api_gateway_resource" "resource" {
  path_part   = "averages"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.api.lambda_invoke_arn
}

resource "aws_api_gateway_deployment" "api" {
  depends_on = [
    aws_api_gateway_integration.integration
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "default"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.api.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
