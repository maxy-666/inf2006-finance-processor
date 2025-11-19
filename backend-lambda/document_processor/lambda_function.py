# backend-lambda/document_processor/lambda_function.py
import boto3
import json

textract_client = boto3.client('textract')

def lambda_handler(event, context):
    """
    Processes a document with Textract and extracts WORD blocks
    with their text and bounding box geometry.
    """
    print("Received event:", json.dumps(event))

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

        words = []
        bboxes = []
        
        for item in response.get("Blocks", []):
            if item["BlockType"] == "WORD":
                words.append(item["Text"])

                geo = item["Geometry"]
                box = geo["BoundingBox"]
                

                x_min = int(box["Left"] * 1000)
                y_min = int(box["Top"] * 1000)
                x_max = int((box["Left"] + box["Width"]) * 1000)
                y_max = int((box["Top"] + box["Height"]) * 1000)
                
                bboxes.append([x_min, y_min, x_max, y_max])
        
        print(f"Extracted {len(words)} words.")

        output = {
            's3_bucket': bucket_name,
            's3_key': object_key,
            'words': words,
            'bboxes': bboxes
        }

        return {
            'statusCode': 200,
            'body': json.dumps(output)
        }

    except Exception as e:
        print(f"Error processing document with Textract: {e}")
        raise e