# backend-iac/s3.tf

resource "aws_s3_bucket" "documents_bucket" {
  bucket = "inf2006-financial-docs-${random_id.bucket_suffix.hex}" # Creates a unique bucket name
}

# New, separate resource for managing S3 bucket versioning
resource "aws_s3_bucket_versioning" "documents_bucket_versioning" {
  bucket = aws_s3_bucket.documents_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Add a random suffix to ensure the bucket name is globally unique
resource "random_id" "bucket_suffix" {
  byte_length = 8
}