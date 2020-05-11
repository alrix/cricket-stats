resource "aws_s3_bucket" "bucket" {
  bucket = lower(var.bucket_name)
  acl    = var.bucket_canned_acl
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
  tags = {
    Name = lower(var.bucket_name)
    ManagedByTerraform = "true"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  depends_on = [aws_s3_bucket.bucket]

  bucket = aws_s3_bucket.bucket.id

  # Block new public ACLs and uploading public objects
  block_public_acls = var.block_public_acls

  # Retroactively remove public access granted through public ACLs
  ignore_public_acls = var.ignore_public_acls

  # Block new public bucket policies
  block_public_policy = var.block_public_policy

  # Retroactivley block public and cross-account access if bucket has public policies
  restrict_public_buckets = var.restrict_public_buckets
}

