# This resource defines the multi-step workflow for processing a document.
resource "aws_sfn_state_machine" "document_processing_workflow" {
  name     = "FinancialDocumentProcessingWorkflow"
  # --- CORRECTED LINE ---
  role_arn = aws_iam_role.processing_workflow_role.arn

  # This is the visual definition of your workflow.
  definition = jsonencode({
    Comment = "A workflow to process financial documents using Textract and custom AI models."
    StartAt = "ExtractTextWithTextract"
    States = {
      # First step: Call the Textract Lambda function
      ExtractTextWithTextract = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          "FunctionName" = aws_lambda_function.document_processor.arn
          "Payload.$"    = "$"
        }
        Next = "ExtractEntitiesWithSageMaker"
      },
      # Second step: Call the SageMaker/Entity Extraction Lambda
      ExtractEntitiesWithSageMaker = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          "FunctionName" = aws_lambda_function.entity_extractor.arn
          "Payload.$"    = "$.Payload"
        }
        End = true
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
  # --- CORRECTED LINE ---
  role_arn  = aws_iam_role.processing_workflow_role.arn

  # This part reformats the S3 event into the format our first Lambda expects
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