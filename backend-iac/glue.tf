# 1. Create a Database for our analytics
resource "aws_glue_catalog_database" "analytics_db" {
  name = "inf2006_analytics_db"
}

# 2. Create an IAM role for the Glue Crawler
resource "aws_iam_role" "glue_crawler_role" {
  name = "glue-crawler-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
    }]
  })
}

# 3. Give the role permission to read our Data Lake S3 bucket
resource "aws_iam_role_policy" "glue_crawler_policy" {
  name = "GlueCrawlerS3Policy"
  role = aws_iam_role.glue_crawler_role.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:ListBucket"],
        Resource = [
          aws_s3_bucket.analytics_datalake.arn,
          "${aws_s3_bucket.analytics_datalake.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = "glue:*", # Broad permissions for simplicity
        Resource = "*"
      }
    ]
  })
}

# 4. Define the Crawler
resource "aws_glue_crawler" "analytics_crawler" {
  name          = "inf2006-analytics-crawler"
  database_name = aws_glue_catalog_database.analytics_db.name
  role          = aws_iam_role.glue_crawler_role.arn

  s3_target {
    path = "s3://${aws_s3_bucket.analytics_datalake.bucket}/processed_data/"
  }

  # This tells Glue to treat files in the same folder as one table
  configuration = jsonencode({
    "Version" : 1.0,
    "CrawlerOutput" : {
      "Partitions" : { "AddOrUpdateBehavior" : "InheritFromTable" }
    },
    "Grouping" : {
      "TableGroupingPolicy" : "CombineCompatibleSchemas"
    }
  })

  # This tells the crawler to create a table named "documents"
  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }
}