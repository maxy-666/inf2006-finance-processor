# backend-iac/lambda.tf

# --- 1. Presigned URL Generator ---
data "archive_file" "presigned_url_lambda_zip" {
  type        = "zip"
  source_dir  = "../backend-lambda/presigned_url_generator/"
  output_path = "presigned_url_lambda.zip"
}

resource "aws_lambda_function" "presigned_url_generator" {
  function_name    = "generate-presigned-url"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  role             = aws_iam_role.presigned_url_lambda_role.arn
  filename         = data.archive_file.presigned_url_lambda_zip.output_path
  source_code_hash = data.archive_file.presigned_url_lambda_zip.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.documents_bucket.bucket
      FORCE_DEPLOY = "v1"
    }
  }
}

# --- 2. Document Processor (OCR) ---
data "archive_file" "processing_lambda_zip" {
  type        = "zip"
  source_dir  = "../backend-lambda/document_processor/"
  output_path = "document_processor_lambda.zip"
}

resource "aws_lambda_function" "document_processor" {
  function_name    = "process-financial-document"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  role             = aws_iam_role.processing_workflow_role.arn
  filename         = data.archive_file.processing_lambda_zip.output_path
  source_code_hash = data.archive_file.processing_lambda_zip.output_base64sha256
  timeout          = 30
}

# --- 3. Entity Extractor (Model 2) ---
data "archive_file" "entity_extractor_lambda_zip" {
  type        = "zip"
  source_dir  = "../backend-lambda/entity_extractor/"
  output_path = "entity_extractor_lambda.zip"
}

resource "aws_lambda_function" "entity_extractor" {
  function_name    = "extract-entities-from-text"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  role             = aws_iam_role.processing_workflow_role.arn
  filename         = data.archive_file.entity_extractor_lambda_zip.output_path
  source_code_hash = data.archive_file.entity_extractor_lambda_zip.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      SAGEMAKER_ENDPOINT_NAME = "inf2006-entity-extraction-endpoint"
    }
  }
}

# --- 4. Expense Categorizer (Model 3) ---
# This was likely the missing block causing your error!
data "archive_file" "categorizer_zip" {
  type        = "zip"
  source_dir  = "../backend-lambda/expense_categorizer/"
  output_path = "expense_categorizer.zip"
}

resource "aws_lambda_function" "expense_categorizer" {
  function_name    = "categorize-expense"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  role             = aws_iam_role.processing_workflow_role.arn
  filename         = data.archive_file.categorizer_zip.output_path
  source_code_hash = data.archive_file.categorizer_zip.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      # Ensure this matches your actual SageMaker endpoint name exactly
      SAGEMAKER_ENDPOINT_NAME = "inf2006-expense-categorization-endpoint"
    }
  }
}

# --- 5. Save to DynamoDB ---
data "archive_file" "saver_zip" {
  type        = "zip"
  source_dir  = "../backend-lambda/save_to_dynamodb/"
  output_path = "save_to_dynamodb.zip"
}

resource "aws_lambda_function" "save_to_dynamodb" {
  function_name    = "save-processed-document"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  role             = aws_iam_role.processing_workflow_role.arn
  filename         = data.archive_file.saver_zip.output_path
  source_code_hash = data.archive_file.saver_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.processed_documents.name
    }
  }
}

# --- 6. ETL (Stream to S3) ---
data "archive_file" "etl_zip" {
  type        = "zip"
  source_dir  = "../backend-lambda/etl_stream_to_s3/"
  output_path = "etl_stream_to_s3.zip"
}

resource "aws_lambda_function" "etl_stream_to_s3" {
  function_name    = "etl-dynamo-stream-to-s3"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  role             = aws_iam_role.etl_lambda_role.arn
  filename         = data.archive_file.etl_zip.output_path
  source_code_hash = data.archive_file.etl_zip.output_base64sha256

  environment {
    variables = {
      DATALAKE_BUCKET_NAME = aws_s3_bucket.analytics_datalake.bucket
    }
  }
}