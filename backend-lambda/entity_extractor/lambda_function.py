import boto3
import json
import os

# Create a SageMaker runtime client
sagemaker_runtime = boto3.client('sagemaker-runtime')

# Get the endpoint name from an environment variable
SAGEMAKER_ENDPOINT_NAME = os.environ.get('SAGEMAKER_ENDPOINT_NAME')

def lambda_handler(event, context):
    """
    Receives the raw text output from the Textract Lambda,
    calls the SageMaker endpoint for entity extraction,
    and returns the structured JSON output.
    """
    print("Received event:", json.dumps(event))
    
    # The 'event' will be the output from your first Lambda.
    # We are assuming it returns a JSON object with a key 'detected_lines'.
    detected_lines = event.get('detected_lines', [])
    
    # Join the lines into a single string for the model
    # (Note: Your model may expect a different input format)
    input_text = "\n".join(detected_lines)

    # The payload format depends on what your Hugging Face model expects.
    # A common format is a dictionary with an "inputs" key.
    payload = {"inputs": input_text}

    try:
        # Call the SageMaker endpoint
        response = sagemaker_runtime.invoke_endpoint(
            EndpointName=SAGEMAKER_ENDPOINT_NAME,
            ContentType='application/json',
            Body=json.dumps(payload)
        )
        
        # Read and decode the response from the model
        result_json = json.loads(response['Body'].read().decode())
        
        print("Successfully received response from SageMaker:", result_json)
        
        # This result will be passed to the next step in the workflow
        return result_json

    except Exception as e:
        print(f"Error invoking SageMaker endpoint: {e}")
        # Re-raise the exception to fail the Step Functions task
        raise e