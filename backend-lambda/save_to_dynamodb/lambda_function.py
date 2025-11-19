# backend-lambda/save_to_dynamodb/lambda_function.py
import boto3
import json
import os
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
TABLE_NAME = os.environ['TABLE_NAME']
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    print("Saving to DB:", json.dumps(event))
    
    try:
        body = event 
        document_id = body.get('document_id')
        
        if not document_id:
            raise ValueError("Missing document_id")

        body['processed_at'] = datetime.utcnow().isoformat()

        # Save to DynamoDB
        table.put_item(Item=body)
        
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Data saved successfully', 'id': document_id})
        }
        
    except Exception as e:
        print(f"Error saving to DynamoDB: {e}")
        raise e