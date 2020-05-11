# Outputs
output "s3_bucket_name" {
  value = module.s3_bucket.bucket_id
}

output "api_url" {
  value = aws_api_gateway_deployment.api.invoke_url
}
