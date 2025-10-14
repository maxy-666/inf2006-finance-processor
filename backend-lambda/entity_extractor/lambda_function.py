# backend-lambda/entity_extractor/lambda_function.py

import boto3
import json
import os

sagemaker_runtime = boto3.client('sagemaker-runtime')
SAGEMAKER_ENDPOINT_NAME = os.environ.get('SAGEMAKER_ENDPOINT_NAME')

def lambda_handler(event, context):
    """
    Receives the output from the Textract Lambda, parses it,
    calls the SageMaker endpoint, and returns the structured JSON output.
    """
    print("Received event:", json.dumps(event))
    
    # --- THIS IS THE FIX ---
    # The actual data is in a JSON string inside the 'body' field.
    # We need to parse this string to get to the 'detected_lines'.
    try:
        body = json.loads(event.get('body', '{}'))
        detected_lines = body.get('detected_lines', [])
    except (json.JSONDecodeError, TypeError):
        detected_lines = []
    # -----------------------

    if not detected_lines:
        print("Warning: No detected lines found in the input payload.")
        return []

    input_text = "\n".join(detected_lines)
    payload = {"inputs": input_text}

    try:
        response = sagemaker_runtime.invoke_endpoint(
            EndpointName=SAGEMAKER_ENDPOINT_NAME,
            ContentType='application/json',
            Body=json.dumps(payload)
        )
        
        result_json = json.loads(response['Body'].read().decode())
        print("Successfully received response from SageMaker:", result_json)
        
        return result_json

    except Exception as e:
        print(f"Error invoking SageMaker endpoint: {e}")
        raise e