import boto3
from botocore.exceptions import ClientError
import requests
import os

def handle(event, context):
    source_url = 'https://raw.githubusercontent.com/datasciencedojo/datasets/master/titanic.csv'
    s3_file_name = 'titanic.csv'
    bucket_name = 'example-titanic'
    
    response = requests.get(source_url, stream=True)
    try:
        s3_client = boto3.client(
            service_name = "s3"
        )
        s3_client.create_bucket(Bucket=bucket_name)
        s3_client.upload_fileobj(response.raw, bucket_name, s3_file_name)
        environ_str = str(os.environ)
    except ClientError as e:
        error_code = e.response['Error']['Code']
        
        if error_code in( 'BucketAlreadyOwnedByYou', 'BucketAlreadyExists'):
            pass
        else:
            return {
                "body": {
                    "message": f"An error occurred: {e}",
                },
                "statusCode": 400,
            }        
    except Exception as e:
        return {
            "body": {
                "message": f"An error occurred: {e}",
            },
            "statusCode": 400,
        }        
    return {
        "body": {
            "message": '"example-titanic" bucket well created'
        },
        "statusCode": 200,
    }