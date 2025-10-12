# backend-lambda/presigned_url_generator/lambda_function.py

import boto3
import os
import uuid
import json
from botocore.exceptions import ClientError

s3_client = boto3.client('s3')
BUCKET_NAME = os.environ.get('BUCKET_NAME')

# Define headers here to be reused
CORS_HEADERS = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'GET, PUT'
}

def lambda_handler(event, context):
    """
    Generates a pre-signed URL for uploading a file to S3.
    """
    object_key = f"uploads/{uuid.uuid4()}"

    try:
        # Check if the bucket name is configured
        if not BUCKET_NAME:
            raise ValueError("BUCKET_NAME environment variable is not set.")

        presigned_url = s3_client.generate_presigned_url(
            'put_object',
            Params={'Bucket': BUCKET_NAME, 'Key': object_key},
            ExpiresIn=600
        )

        # Success response
        return {
            'statusCode': 200,
            'headers': CORS_HEADERS,
            'body': json.dumps({'uploadURL': presigned_url, 'key': object_key})
        }

    except Exception as e:
        print(f"Error generating pre-signed URL: {e}")
        # --- THIS IS THE CRUCIAL FIX ---
        # Now, the error response also includes the CORS headers.
        return {
            'statusCode': 500,
            'headers': CORS_HEADERS,
            'body': json.dumps({'error': f"Could not generate upload URL: {str(e)}"})
        }