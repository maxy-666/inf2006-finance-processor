# backend-iac/s3.tf

resource "aws_s3_bucket" "documents_bucket" {
  bucket = "inf2006-financial-docs-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

# Add this new resource to configure CORS on the bucket
resource "aws_s3_bucket_cors_configuration" "documents_bucket_cors" {
  bucket = aws_s3_bucket.documents_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
  }
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

# --- Analytics Data Lake ---
resource "aws_s3_bucket" "analytics_datalake" {
  # We use a fixed name here for simplicity, but add a random_id in production
  bucket = "inf2006-analytics-datalake" 

  # Enforce private access
  acl    = "private"

  tags = {
    Project = "INF2006-Analytics"
  }
}