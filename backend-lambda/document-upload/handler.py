import json
import base64
import os
import boto3
import logging

# Set up logging for CloudWatch
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialise Boto3 clients
s3_client = boto3.client('s3')
textract_client = boto3.client('textract')

# Retrieve the S3 bucket name from the environment variable set by Terraform
RAW_DOCS_BUCKET = os.environ.get('RAW_DOCS_BUCKET') 
# You must ensure this variable is set in the Terraform code!

def lambda_handler(event, context):
    logger.info(f"Received event: {event}")

    # --- 1. Extract and Decode Document from API Gateway Event ---
    try:
        # API Gateway with AWS_PROXY sends the body base64 encoded
        encoded_body = event['body']
        document_bytes = base64.b64decode(encoded_body)
        
        # --- You need to fill this in: Extract a filename from the request ---
        # For a PoC, we will generate a unique filename
        # In the final version, you would pass this from the frontend via headers or query parameters
        file_name = 'invoice-' + context.aws_request_id + '.pdf'
        
    except (KeyError, TypeError, ValueError) as e:
        logger.error(f"Error processing request body: {e}")
        return {
            'statusCode': 400,
            'body': json.dumps({"error": "Invalid request format or missing document body."})
        }
    
    # --- 2. Upload Document to S3 ---
    try:
        s3_client.put_object(
            Bucket=RAW_DOCS_BUCKET,
            Key=file_name,
            Body=document_bytes,
            ContentType='application/pdf' # Adjust based on expected file type
        )
        logger.info(f"Successfully uploaded {file_name} to {RAW_DOCS_BUCKET}")
        
    except Exception as e:
        logger.error(f"S3 Upload Error: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({"error": f"Failed to upload document to S3: {e}"})
        }

    # --- 3. Trigger Textract Asynchronously (Best Practice for large files) ---
    try:
        # We use the asynchronous API 'StartDocumentTextDetection' 
        # as it supports larger documents (PDFs, multi-page)
        textract_response = textract_client.start_document_text_detection(
            DocumentLocation={
                'S3Object': {
                    'Bucket': RAW_DOCS_BUCKET,
                    'Name': file_name
                }
            }
            # Note: For production, you MUST add a NotificationChannel (SNS) here 
            # to get the results, but we skip it for this basic PoC return value.
        )

        job_id = textract_response['JobId']
        logger.info(f"Textract job started with ID: {job_id}")
        
        # --- 4. Return Success Response to Client ---
        return {
            'statusCode': 202, # 202 Accepted, since the job is running in the background
            'headers': {
                # This header is critical for your front-end web app to work (CORS)
                "Access-Control-Allow-Origin": "*", 
            },
            'body': json.dumps({
                "message": "Document uploaded and Textract job started successfully.",
                "jobId": job_id,
                "file": file_name
            })
        }
        
    except Exception as e:
        logger.error(f"Textract Error: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({"error": f"Textract processing failed: {e}"})
        }