resource "aws_s3_bucket" "inf2006-s3frontend" {
  bucket = "inf2006-s3frontend" 

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

  website {
    index_document = "index.html"
    error_document = "error.html" 
  }
}

resource "aws_s3_bucket_versioning" "inf2006-s3frontend_versioning" {
  bucket = aws_s3_bucket.inf2006-s3frontend.id
  versioning_configuration {
    status = "Suspended"
  }
}

