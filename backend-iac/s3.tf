# backend-iac/s3.tf

resource "aws_s3_bucket" "documents_bucket" {
  bucket = "inf2006-financial-docs-${random_id.bucket_suffix.hex}"
  # This new line tells Terraform to delete the bucket even if it has files in it.
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "documents_bucket_versioning" {
  bucket = aws_s3_bucket.documents_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}