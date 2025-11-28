import boto3
client = boto3.client('quicksight')

def lambda_handler(event, context):
    # Trigger a SPICE ingestion to refresh the data
    client.create_ingestion(
        DataSetId='f299841c-90a8-4f0a-b683-6b93b99262ab',
        IngestionId=f'refresh-{context.aws_request_id}',
        AwsAccountId='335360747232'
    )
    return {"status": "refresh_started"}

import boto3
import json

qs = boto3.client('quicksight')

def lambda_handler(event, context):
    response = qs.generate_embed_url_for_anonymous_user(
        AwsAccountId='335360747232',
        Namespace='default',
        AuthorizedResourceArns=['arn:aws:quicksight:us-east-1:'],
        ExperienceConfiguration={
            'Dashboard': {'InitialDashboardId': 'f299841c-90a8-4f0a-b683-6b93b99262ab'}
        }
    )

    return {
        'statusCode': 200,
        'headers': {"Access-Control-Allow-Origin": "*"},
        'body': json.dumps({'url': response['EmbedUrl']})
    }