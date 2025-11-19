# 1. Create an Athena Workgroup
resource "aws_athena_workgroup" "analytics_workgroup" {
  name = "inf2006-analytics-workgroup"
  
  configuration {
    result_configuration {
      # This is a new S3 bucket Athena needs to store query results
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/"
    }
  }
}

# 2. Create the S3 bucket for Athena results
resource "aws_s3_bucket" "athena_results" {
  bucket = "inf2006-athena-query-results"
  acl    = "private"

  # Add a lifecycle rule to auto-delete old query results
  lifecycle_rule {
    enabled = true
    expiration {
      days = 7
    }
  }
}