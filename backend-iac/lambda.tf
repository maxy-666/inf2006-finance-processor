# backend-iac/lambda.tf

# Data source for zipping the Lambda code
data "archive_file" "presigned_url_lambda_zip" {
  type        = "zip"
  source_dir  = "../backend-lambda/presigned_url_generator/"
  output_path = "presigned_url_lambda.zip"
}

data "archive_file" "processing_lambda_zip" {
  type        = "zip"
  source_dir  = "../backend-lambda/document_processor/"
  output_path = "document_processor_lambda.zip"
}

# 1. Pre-signed URL generator Lambda
resource "aws_lambda_function" "presigned_url_generator" {
  function_name    = "generate-presigned-url"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  # --- CORRECTED LINE ---
  role             = local.lab_role_arn
  # ------------------------
  filename         = data.archive_file.presigned_url_lambda_zip.output_path
  source_code_hash = data.archive_file.presigned_url_lambda_zip.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.documents_bucket.bucket
    }
  }
}

# 2. Document processor Lambda
resource "aws_lambda_function" "document_processor" {
  function_name    = "process-financial-document"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  # --- CORRECTED LINE ---
  role             = local.lab_role_arn
  # ------------------------
  filename         = data.archive_file.processing_lambda_zip.output_path
  source_code_hash = data.archive_file.processing_lambda_zip.output_base64sha256
  timeout          = 30
}

# --- New Lambda for Entity Extraction ---

data "archive_file" "entity_extractor_lambda_zip" {
  type        = "zip"
  source_dir  = "../backend-lambda/entity_extractor/"
  output_path = "entity_extractor_lambda.zip"
}

resource "aws_lambda_function" "entity_extractor" {
  function_name    = "extract-entities-from-text"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  # --- CORRECTED LINE ---
  role             = local.lab_role_arn
  # ------------------------
  filename         = data.archive_file.entity_extractor_lambda_zip.output_path
  source_code_hash = data.archive_file.entity_extractor_lambda_zip.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      # This name must EXACTLY match the endpoint you created
      SAGEMAKER_ENDPOINT_NAME = "inf2006-entity-extraction-endpoint"
    }
  }
}