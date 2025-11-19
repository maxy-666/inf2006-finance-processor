import boto3
import json
import os

# Initialize client
sagemaker_runtime = boto3.client('sagemaker-runtime')
SAGEMAKER_ENDPOINT_NAME = os.environ.get('SAGEMAKER_ENDPOINT_NAME')

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))
    
    try:
        # 1. Extract entities directly from the event (from Model 2)
        if 'entities' in event:
            entities = event['entities']
        elif 'company' in event or 'total' in event:
            entities = event 
        else:
            entities = {}

        s3_key = event.get('s3_key', 'unknown')
        s3_bucket = event.get('s3_bucket', 'unknown')
        
        print(f"Entities received from Model 2: {entities}")

        category = "Uncategorized"

        # 2. Call Model 3 ONLY if we have real entities
        if entities and SAGEMAKER_ENDPOINT_NAME:
            try:
                company = " ".join(entities.get('company', [])) if isinstance(entities.get('company'), list) else entities.get('company', '')
                total = " ".join(entities.get('total', [])) if isinstance(entities.get('total'), list) else entities.get('total', '')
                address = " ".join(entities.get('address', [])) if isinstance(entities.get('address'), list) else entities.get('address', '')

                text_input = f"{company} {total} {address}".strip()
                
                if not text_input: 
                    text_input = "Unknown Transaction"

                payload = json.dumps({
                    "inputs": [text_input] 
                })
                
                print(f"Invoking Model 3: {SAGEMAKER_ENDPOINT_NAME} with input: {text_input}")
                response = sagemaker_runtime.invoke_endpoint(
                    EndpointName=SAGEMAKER_ENDPOINT_NAME,
                    ContentType='application/json',
                    Body=payload
                )
                
                response_body = response['Body'].read().decode()
                print("Model 3 Output:", response_body)
                
                output_json = json.loads(response_body)
                
                if isinstance(output_json, list) and len(output_json) > 0:
                    first_item = output_json[0]
                    if isinstance(first_item, list): 
                         first_item = first_item[0]
                    
                    if isinstance(first_item, dict):
                        category = first_item.get('label', str(first_item))
                    else:
                        category = str(first_item)
                elif isinstance(output_json, dict):
                     category = output_json.get('label', str(output_json))
                
            except Exception as e:
                print(f"Error calling Model 3: {e}")
                category = "Uncategorized (Model Error)"
        else:
            print("No entities found by Model 2 (or endpoint missing). Skipping Model 3.")

        # 3. Return result
        result = {
            'document_id': s3_key,
            'bucket': s3_bucket,
            'entities': entities,
            'category': category
        }

        return {
            'statusCode': 200,
            'body': json.dumps(result)
        }
    
    except Exception as e:
        print(f"Critical error: {e}")
        raise e