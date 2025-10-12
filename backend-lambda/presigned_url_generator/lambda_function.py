# backend-lambda/presigned_url_generator/lambda_function.py

import boto3
import os
import uuid
import json
from botocore.exceptions import ClientError

s3_client = boto3.client('s3')
BUCKET_NAME = os.environ.get('BUCKET_NAME')

def lambda_handler(event, context):
    """
    Generates a pre-signed URL for uploading a file to S3.
    """
    object_key = f"uploads/{uuid.uuid4()}"

    try:
        presigned_url = s3_client.generate_presigned_url(
            'put_object',
            Params={'Bucket': BUCKET_NAME, 'Key': object_key, 'ContentType': 'image/jpeg'}, # Assuming image uploads
            ExpiresIn=600  # URL expires in 10 minutes
        )

        # --- THIS IS THE CRUCIAL FIX ---
        # We are now explicitly adding the CORS headers to the response.
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'GET, PUT'
            },
            'body': json.dumps({'uploadURL': presigned_url, 'key': object_key})
        }
        # --------------------------------

    except ClientError as e:
        print(f"Error generating pre-signed URL: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Could not generate upload URL'})
        }