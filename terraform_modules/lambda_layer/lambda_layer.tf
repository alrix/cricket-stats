locals {
  layer_archive = "../output/${var.lambda_layer_archive}"
}

data "archive_file" "lambda_zip" {
    type        = "zip"
    source_dir  = var.lambda_layer_source
    output_path = local.layer_archive
}

resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name = var.lambda_layer_name
  filename = local.layer_archive
  compatible_runtimes = var.compatible_runtimes
	source_code_hash = filebase64sha256(local.layer_archive)
}

