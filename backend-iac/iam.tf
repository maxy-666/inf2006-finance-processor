# backend-iac/iam.tf

locals {
  # We manually construct the ARN to avoid the iam:GetRole permission error.
  # Replace "381491898127" with the ID from your AWS console.
  lab_role_arn = "arn:aws:iam::381491898127:role/LabRole"
}