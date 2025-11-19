import boto3
import json
import os
from datetime import datetime

s3_client = boto3.client('s3')
BUCKET_NAME = os.environ['DATALAKE_BUCKET_NAME']

def lambda_handler(event, context):
    """
    Receives a stream of records from DynamoDB, formats them
    as JSON Lines (JSONL), and saves them to the S3 Data Lake.
    """
    records_to_save = []
    
    for record in event['Records']:
        if record['eventName'] == 'INSERT':
            new_image = record['dynamodb']['NewImage']
            
            # Simple deserializer
            python_data = {}
            for key, data_type in new_image.items():
                if 'S' in data_type:
                    python_data[key] = data_type['S']
                elif 'N' in data_type:
                    python_data[key] = data_type['N']
                elif 'BOOL' in data_type:
                    python_data[key] = data_type['BOOL']
                elif 'M' in data_type:
                    python_data[key] = data_type['M'] 
            
            records_to_save.append(json.dumps(python_data))

    if not records_to_save:
        print("No new records to save.")
        return
        
    output_data = "\n".join(records_to_save)
    
    now = datetime.utcnow()
    file_key = f"processed_data/year={now.year}/month={now.month}/day={now.day}/{now.isoformat()}.jsonl"
    
    try:
        s3_client.put_object(
            Bucket=BUCKET_NAME,
            Key=file_key,
            Body=output_data
        )
        print(f"Successfully saved {len(records_to_save)} records to {file_key}")
        return {'status': 'success'}
        
    except Exception as e:
        print(f"Error saving to S3: {e}")
        raise e