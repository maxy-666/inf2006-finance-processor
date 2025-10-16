# Defines the S3 bucket for hosting the frontend website.
resource "aws_s3_bucket" "inf2006-s3frontend" {
  bucket = "inf2006-s3frontend" # The unique name for your bucket.

  # This policy makes the objects in the bucket publicly readable.
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "arn:aws:s3:::inf2006-s3frontend/*"
      },
    ]
  })

  # Configures the bucket to act as a website.
  website {
    index_document = "index.html"
    error_document = "error.html" # Note: You'll need to upload an error.html file for this to work.
  }
}

# It is best practice to manage versioning in a separate resource block.
resource "aws_s3_bucket_versioning" "inf2006-s3frontend_versioning" {
  bucket = aws_s3_bucket.inf2006-s3frontend.id
  versioning_configuration {
    # Once versioning is enabled, it can only be suspended, not disabled.
    status = "Suspended"
  }
}

