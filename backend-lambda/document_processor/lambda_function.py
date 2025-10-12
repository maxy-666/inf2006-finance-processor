import boto3
import json

textract_client = boto3.client('textract')

def lambda_handler(event, context):
    """
    Processes a document uploaded to S3 using Amazon Textract.
    """
    print("Received event:", json.dumps(event))

    # Get the bucket and key from the S3 event
    s3_record = event['Records'][0]['s3']
    bucket_name = s3_record['bucket']['name']
    object_key = s3_record['object']['key']
    
    print(f"Processing document: s3://{bucket_name}/{object_key}")

    try:
        response = textract_client.detect_document_text(
            Document={
                'S3Object': {
                    'Bucket': bucket_name,
                    'Name': object_key
                }
            }
        )

        # Extract and print detected lines of text
        lines = []
        for item in response.get("Blocks", []):
            if item["BlockType"] == "LINE":
                lines.append(item["Text"])
        
        print("\n--- Detected Text ---")
        for line in lines:
            print(line)
        print("--- End of Detected Text ---\n")

        # Future step: Save this structured data to DynamoDB or trigger the next Lambda.
        
        return {
            'statusCode': 200,
            'body': json.dumps({'detected_lines': lines})
        }

    except Exception as e:
        print(f"Error processing document with Textract: {e}")
        raise e