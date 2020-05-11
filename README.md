# Cricket Stats

Terraform code to create AWS Lambda functions for calculating
batting and bowling averages for a cricket season.

This sets up 
* S3 bucket which you upload xlsx files with your teams
cricket reports.
* ETL lambda function to process xlsx files
* API lambda function to query averages
* API gateway to the query function
* S3 trigger for the ETL function

### Pre-requisite tasks

1. Generate python archive for lambda layer
```
$ pip install -t output/lambda_layer/python -r functions/requirements.txt 
```

2. Create terraform/terraform.tfvars:
```
name = "somename"
```

### Deploying

Run terraform apply to deploy.
