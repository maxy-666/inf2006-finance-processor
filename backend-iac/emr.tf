# backend-iac/emr.tf

# 1. IAM Role for EMR Service
resource "aws_iam_role" "emr_service_role" {
  name = "emr-service-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "elasticmapreduce.amazonaws.com" }
    }]
  })
}
resource "aws_iam_role_policy_attachment" "emr_service_attach" {
  role       = aws_iam_role.emr_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
}

# 2. IAM Role for EC2 Instances (The nodes)
resource "aws_iam_role" "emr_ec2_role" {
  name = "emr-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}
resource "aws_iam_role_policy_attachment" "emr_ec2_attach" {
  role       = aws_iam_role.emr_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role"
}

# Instance Profile
resource "aws_iam_instance_profile" "emr_ec2_profile" {
  name = "emr-ec2-profile"
  role = aws_iam_role.emr_ec2_role.name
}

# 3. The EMR Cluster
resource "aws_emr_cluster" "analytics_cluster" {
  name          = "inf2006-spark-cluster"
  release_label = "emr-6.10.0" # Contains Spark 3.3
  applications  = ["Spark", "Hadoop"]

  service_role = aws_iam_role.emr_service_role.arn
  
  ec2_attributes {
    instance_profile = aws_iam_instance_profile.emr_ec2_profile.arn
    # Uses the default VPC/Subnet found by Terraform provider
    key_name = "project-key"
  }

  # Hardware Configuration
  master_instance_group {
    instance_type = "m5.xlarge"
  }
  core_instance_group {
    instance_type  = "m5.xlarge"
    instance_count = 2
  }

  # Log to S3 so we can debug
  log_uri = "s3://${aws_s3_bucket.analytics_datalake.bucket}/emr-logs/"

  # Tags
  tags = {
    Project = "BigData-Batch-Layer"
  }
}