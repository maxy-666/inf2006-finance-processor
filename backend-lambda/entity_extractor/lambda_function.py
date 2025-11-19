# backend-lambda/entity_extractor/lambda_function.py
import boto3
import json
import os

sagemaker_runtime = boto3.client('sagemaker-runtime')
SAGEMAKER_ENDPOINT_NAME = os.environ.get('SAGEMAKER_ENDPOINT_NAME')

def lambda_handler(event, context):
    """
    Receives parsed words and bboxes, sends them to SageMaker,
    and returns the structured JSON output.
    """
    print("Received event:", json.dumps(event))
    
    try:
        words = event.get('words', [])
        bboxes = event.get('bboxes', [])
        s3_bucket = event.get('s3_bucket')
        s3_key = event.get('s3_key')
        
    except Exception as e:
        print(f"Error parsing input: {e}")
        raise e

    if not words or not bboxes:
        print("Warning: No words or bboxes found in the input payload.")
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'No words or bboxes found'})
        }

    payload = {
        "words": words,
        "bboxes": bboxes 
    }

    try:
        response = sagemaker_runtime.invoke_endpoint(
            EndpointName=SAGEMAKER_ENDPOINT_NAME,
            ContentType='application/json',
            Body=json.dumps(payload)
        )
        
        result_json = json.loads(response['Body'].read().decode())
        print("Successfully received response from SageMaker:", result_json)
        
        result_json['s3_bucket'] = s3_bucket
        result_json['s3_key'] = s3_key
        
        return {
            'statusCode': 200,
            'body': json.dumps(result_json)
        }

    except Exception as e:
        print(f"Error invoking SageMaker endpoint: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }