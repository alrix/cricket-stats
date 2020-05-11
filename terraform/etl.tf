# Add policy to IAM role to allow ETL Lambda Function S3 bucket access
resource "aws_iam_role_policy_attachment" "etl_s3_bucket_access" {
  role       = module.etl.lambda_iam_role_name
  policy_arn = aws_iam_policy.etl_s3_bucket_access.arn
}

resource "aws_iam_policy" "etl_s3_bucket_access" {
  name        = "${module.etl.lambda_iam_role_name}_s3_bucket_access"
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
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListMultipartUploadParts",
        "s3:AbortMultipartUpload"
      ],
      "Resource": "arn:aws:s3:::${module.s3_bucket.bucket_id}/*"
    }
  ]
}
EOF
}

# Add Trigger for the ETL
resource "aws_s3_bucket_notification" "etl_trigger" {
    bucket = module.s3_bucket.bucket_id
    lambda_function {
        lambda_function_arn = module.etl.lambda_arn
        events              = ["s3:ObjectCreated:*"]
        filter_suffix       = ".xlsx"
    }
}

resource "aws_lambda_permission" "etl_trigger" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.etl.lambda_arn
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3_bucket.bucket_arn
}
