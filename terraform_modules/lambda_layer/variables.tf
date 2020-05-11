variable lambda_layer_name {}
variable lambda_layer_source {
  default = "../output/lambda_layer"
}
variable lambda_layer_archive {
  description = "Object containing the functions deployment package"
  default = "python.zip"
}
variable compatible_runtimes {
  default = ["python3.8"]
}
