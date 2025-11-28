# Multi-step workflow for processing a document.
resource "aws_sfn_state_machine" "document_processing_workflow" {
  name     = "FinancialDocumentProcessingWorkflow"
  role_arn = aws_iam_role.processing_workflow_role.arn

  definition = jsonencode({
    Comment = "Full pipeline: OCR -> Entity Extraction -> Categorization -> DB Save"
    StartAt = "ExtractTextWithTextract"
    States = {
      # Step 1: Call Textract
      ExtractTextWithTextract = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          "FunctionName" = aws_lambda_function.document_processor.arn
          "Payload.$"    = "$"
        }
        Retry = [
          {
            "ErrorEquals": ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException", "Lambda.TooManyRequestsException", "States.TaskFailed"],
            "IntervalSeconds": 2,
            "MaxAttempts": 6,
            "BackoffRate": 2.0
          }
        ]
        ResultSelector = {
          "parsed_body.$" = "States.StringToJson($.Payload.body)"
        }
        ResultPath = "$.textract_output"
        Next       = "ExtractEntitiesWithSageMaker"
      },

      # Step 2: Call SageMaker (Entity Extraction)
      ExtractEntitiesWithSageMaker = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          "FunctionName" = aws_lambda_function.entity_extractor.arn
          "Payload.$"    = "$.textract_output.parsed_body"
        }
        Retry = [
          {
            "ErrorEquals": ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException", "Lambda.TooManyRequestsException", "States.TaskFailed"],
            "IntervalSeconds": 2,
            "MaxAttempts": 6,
            "BackoffRate": 2.0
          }
        ]
        ResultSelector = {
          "parsed_body.$" = "States.StringToJson($.Payload.body)"
        }
        ResultPath = "$.sagemaker_output"
        Next       = "CategorizeExpense"
      },

      # Step 3: Categorize Expense (Model 3)
      CategorizeExpense = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          "FunctionName" = aws_lambda_function.expense_categorizer.arn
          "Payload.$"    = "$.sagemaker_output.parsed_body"
        }
        Retry = [
          {
            "ErrorEquals": ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException", "Lambda.TooManyRequestsException", "States.TaskFailed"],
            "IntervalSeconds": 2,
            "MaxAttempts": 6,
            "BackoffRate": 2.0
          }
        ]
        ResultSelector = {
          "parsed_body.$" = "States.StringToJson($.Payload.body)"
        }
        ResultPath = "$.categorizer_output"
        Next       = "SaveToDynamoDB"
      },

      # Step 4: Save to DB
      SaveToDynamoDB = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          "FunctionName" = aws_lambda_function.save_to_dynamodb.arn
          "Payload.$"    = "$.categorizer_output.parsed_body"
        }
        Retry = [
          {
            "ErrorEquals": ["DynamoDB.ProvisionedThroughputExceededException", "Lambda.TooManyRequestsException"],
            "IntervalSeconds": 1,
            "MaxAttempts": 3,
            "BackoffRate": 2.0
          }
        ]
        Next = "RefreshQuickSight" 
      },
      # --- REFRESH DASHBOARD ---
      RefreshQuickSight = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          "FunctionName" = aws_lambda_function.refresh_quicksight.arn
          "Payload.$"    = "$" 
        }
        Catch = [
            {
                "ErrorEquals": ["States.ALL"],
                "Next": "WorkflowComplete"
            }
        ]
        Next = "WorkflowComplete"
      },

      # Dummy end state
      WorkflowComplete = {
        Type = "Pass"
        End  = true
      }
    }
  })
}

# --- New S3 Trigger using EventBridge ---

# 1. Enable EventBridge notifications on the S3 bucket
resource "aws_s3_bucket_notification" "bucket_eventbridge_notification" {
  bucket      = aws_s3_bucket.documents_bucket.id
  eventbridge = true
}

# 2. Create an EventBridge rule to listen for the specific S3 upload event
resource "aws_cloudwatch_event_rule" "s3_upload_rule" {
  name        = "CaptureS3UploadsForStepFunctions"
  description = "Triggers the Step Function workflow when a file is uploaded to the 'uploads/' folder."

  event_pattern = jsonencode({
    "source"      = ["aws.s3"],
    "detail-type" = ["Object Created"],
    "detail"      = {
      "bucket" = {
        "name" = [aws_s3_bucket.documents_bucket.bucket]
      },
      "object" = {
        "key" = [{ "prefix" = "uploads/" }]
      }
    }
  })
}

# 3. Connect the EventBridge rule to the Step Function workflow
resource "aws_cloudwatch_event_target" "step_function_target" {
  rule      = aws_cloudwatch_event_rule.s3_upload_rule.name
  arn       = aws_sfn_state_machine.document_processing_workflow.id
  role_arn  = aws_iam_role.processing_workflow_role.arn

  input_transformer {
    input_paths = {
      "bucket" = "$.detail.bucket.name",
      "key"    = "$.detail.object.key"
    }
    input_template = <<EOF
{
  "Records": [
    {
      "s3": {
        "bucket": {
          "name": <bucket>
        },
        "object": {
          "key": <key>
        }
      }
    }
  ]
}
EOF
  }
}

# 1. Archive for the Refresh Lambda
data "archive_file" "refresh_qs_zip" {
  type        = "zip"
  output_path = "refresh_quicksight.zip"
  source_content_filename = "lambda_function.py"
  source_content = <<EOF
import boto3
import os

client = boto3.client('quicksight')
ACCOUNT_ID = os.environ['ACCOUNT_ID']
DATASET_ID = os.environ['DATASET_ID']

def lambda_handler(event, context):
    try:
        # Trigger an ingestion (refresh) for the SPICE dataset
        client.create_ingestion(
            DataSetId=DATASET_ID,
            IngestionId=f'refresh-{context.aws_request_id}',
            AwsAccountId=ACCOUNT_ID,
            IngestionType='FULL_REFRESH'
        )
        return {"status": "refresh_started"}
    except Exception as e:
        print(f"Error refreshing dataset: {e}")
        # We return success even on fail so we don't break the whole workflow
        return {"status": "failed", "error": str(e)}
EOF
}

# 2. The Lambda Function Resource
resource "aws_lambda_function" "refresh_quicksight" {
  function_name    = "refresh-quicksight-dataset"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  role             = aws_iam_role.processing_workflow_role.arn # Reusing workflow role for simplicity
  filename         = data.archive_file.refresh_qs_zip.output_path
  source_code_hash = data.archive_file.refresh_qs_zip.output_base64sha256

  environment {
    variables = {
      ACCOUNT_ID = data.aws_caller_identity.current.account_id
      DATASET_ID = "YOUR_QUICKSIGHT_DATASET_ID" 
    }
  }
}

# Helper to get your account ID
data "aws_caller_identity" "current" {}