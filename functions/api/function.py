import boto3
import botocore
import pandas as pd
import logging
import os
from botocore.errorfactory import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

console = logging.StreamHandler()
console.setLevel(logging.INFO)
# add the handler to the root logger
logging.getLogger().addHandler(console)

bucket_name = os.environ['S3_BUCKET']

def check_bucket(bucket):
    logger.info('Checking bucket')
    bucket_exists = True
    s3 = boto3.resource('s3')
    if s3.Bucket(bucket).creation_date is None:
       logger.error('Bucket does not exist')
       bucket_exists = False
    else:
       logger.info('Bucket exists')
    return bucket_exists

def check_file(bucket,itemname):
    s3 = boto3.client('s3')
    item_exists = True
    try:
        s3.head_object(Bucket=bucket, Key=itemname)
    except ClientError:
        logger.warning('File does not exist')
        item_exists = False
    else:
        logger.info('File exists')
    return item_exists

def get_averages(bucket,itemname):
    s3 = boto3.resource('s3')
    obj = s3.Object(bucket, itemname)
    logger.info('Reading body of ' + itemname)
    df = pd.read_csv(obj.get()['Body'])
    body = df.to_json(orient='columns')
    return(body)

# Main function. Entrypoint for Lambda
def lambda_handler(event, context):
    body = '{"Status": "Request Failed"}'
    status = 200

    try:
        discipline = event['queryStringParameters']['discipline']
    except KeyError:
        logger.warning('discipline not specified')
    else:
        logger.info("QueryString correct")
        itemname = "api/" + discipline + ".csv"
        logger.info('Grabbing stats for ' + discipline)
    
        # Check if exists
        if check_bucket(bucket_name):
            if check_file(bucket_name,itemname):
                body = get_averages(bucket_name,itemname)

    response = { "statusCode": status, "body": body }
    return response

# Manual invocation of the script (only used for testing)
if __name__ == "__main__":
    # Test function
    test = {}
    test['queryStringParameters'] = { "discipline": "batting" }
    #test['queryStringParameters'] = { "bat": "ball" }
    
    lambda_handler(test,None)

