# 1. Athena Workgroup
resource "aws_athena_workgroup" "analytics_workgroup" {
  name = "inf2006-analytics-workgroup"
  
  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/"
    }
  }
}

# 2. S3 bucket for Athena results
resource "aws_s3_bucket" "athena_results" {
  bucket = "inf2006-athena-query-results"
  acl    = "private"

  lifecycle_rule {
    enabled = true
    expiration {
      days = 7
    }
  }
}