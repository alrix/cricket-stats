variable "bucket_name" {}
variable "bucket_canned_acl" { default = "private" }

variable "block_public_acls" { default = "true" }
variable "ignore_public_acls" { default = "true" }
variable "block_public_policy" { default = "true" }
variable "restrict_public_buckets" { default = "true" }
