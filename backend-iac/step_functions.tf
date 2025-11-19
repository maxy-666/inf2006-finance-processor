# This resource defines the multi-step workflow for processing a document.
resource "aws_sfn_state_machine" "document_processing_workflow" {
  name     = "FinancialDocumentProcessingWorkflow"
  # --- CORRECTED LINE ---
  role_arn = aws_iam_role.processing_workflow_role.arn

  # This is the visual definition of your workflow.
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
        # This takes the output {"statusCode": 200, "body": "..."}
        # It parses the "body" string as JSON
        # And it stores that parsed JSON in a variable "$.parsed_body"
        ResultSelector = {
          "parsed_body.$" = "States.StringToJson($.Payload.body)"
        }
        ResultPath = "$.textract_output"
        Next       = "ExtractEntitiesWithSageMaker"
      },

      # Step 2: Call SageMaker
      ExtractEntitiesWithSageMaker = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          "FunctionName" = aws_lambda_function.entity_extractor.arn
          "Payload.$"    = "$.textract_output.parsed_body" # Pass the parsed body
        }
        ResultSelector = {
          "parsed_body.$" = "States.StringToJson($.Payload.body)"
        }
        ResultPath = "$.sagemaker_output"
        Next       = "CategorizeExpense"
      },

      # Step 3: Categorize Expense
      CategorizeExpense = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          "FunctionName" = aws_lambda_function.expense_categorizer.arn
          "Payload.$"    = "$.sagemaker_output.parsed_body" # Pass the parsed body
        }
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
          "Payload.$"    = "$.categorizer_output.parsed_body" # Pass the final object
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