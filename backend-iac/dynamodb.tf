resource "aws_dynamodb_table" "processed_documents" {
  name             = "inf2006-processed-documents"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "document_id"

  attribute {
    name = "document_id"
    type = "S"
  }

  # CRITICAL FOR PHASE 2: This enables the "Big Data" pipeline
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  tags = {
    Project = "INF2006-Financial-Processor"
  }
}