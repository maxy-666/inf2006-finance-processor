# backend-iac/s3.tf

resource "aws_s3_bucket" "documents_bucket" {
  bucket = "inf2006-financial-docs-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

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
  bucket = "inf2006-analytics-datalake" 

  # Enforce private access
  acl    = "private"

  tags = {
    Project = "INF2006-Analytics"
  }
}


# 1. Disable the "Block All Public Access" setting for this bucket
resource "aws_s3_bucket_public_access_block" "analytics_public_access" {
  bucket = aws_s3_bucket.analytics_datalake.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 2. Add a Bucket Policy to make ONLY the "reports/" folder public
resource "aws_s3_bucket_policy" "allow_public_reports" {
  bucket = aws_s3_bucket.analytics_datalake.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadForReportsFolder",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        # CRITICAL: Restricts public access to ONLY the reports folder
        Resource  = "${aws_s3_bucket.analytics_datalake.arn}/reports/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.analytics_public_access]
}