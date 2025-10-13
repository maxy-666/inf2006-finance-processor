# backend-iac/iam.tf

# 1. IAM Role for the Lambda that generates the pre-signed URL
resource "aws_iam_role" "presigned_url_lambda_role" {
  name = "presigned-url-lambda-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Policy allowing the Lambda to generate a pre-signed URL
resource "aws_iam_policy" "s3_put_presigned_policy" {
  name   = "S3PutObjectPresignedPolicy"
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Action   = "s3:PutObject"
      Effect   = "Allow"
      Resource = "${aws_s3_bucket.documents_bucket.arn}/*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "presigned_lambda_s3" {
  role       = aws_iam_role.presigned_url_lambda_role.name
  policy_arn = aws_iam_policy.s3_put_presigned_policy.arn
}

resource "aws_iam_role_policy_attachment" "presigned_lambda_logs" {
  role       = aws_iam_role.presigned_url_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 2. IAM Role for the main document processing workflow
resource "aws_iam_role" "processing_workflow_role" {
  name = "document-processing-workflow-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      { Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } },
      { Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "states.amazonaws.com" } },
      { Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "sagemaker.amazonaws.com" } },
      # Add trust for EventBridge to start the workflow
      { Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "events.amazonaws.com" } }
    ]
  })
}

# Policy for the workflow
resource "aws_iam_policy" "workflow_permissions_policy" {
  name   = "WorkflowPermissionsPolicy"
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      { Action = "s3:GetObject", Effect = "Allow", Resource = "${aws_s3_bucket.documents_bucket.arn}/*" },
      { Action = "textract:DetectDocumentText", Effect = "Allow", Resource = "*" },
      { Action = "sagemaker:InvokeEndpoint", Effect = "Allow", Resource = "*" },
      { Action = "lambda:InvokeFunction", Effect = "Allow", Resource = "*" },
      { Action = ["ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"], Effect = "Allow", Resource = "arn:aws:ecr:us-east-1:763104351884:repository/huggingface-pytorch-inference" },
      # --- THIS NEW ACTION IS THE FIX ---
      {
        Action   = "states:StartExecution",
        Effect   = "Allow",
        Resource = aws_sfn_state_machine.document_processing_workflow.id
      }
      # ---------------------------------
    ]
  })
}

resource "aws_iam_role_policy_attachment" "workflow_permissions" {
  role       = aws_iam_role.processing_workflow_role.name
  policy_arn = aws_iam_policy.workflow_permissions_policy.arn
}

resource "aws_iam_role_policy_attachment" "workflow_logs" {
  role       = aws_iam_role.processing_workflow_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}