# Determine who's running the show
data "aws_caller_identity" "current" {
}

# Determine the region
data "aws_region" "region" {
}
