output "role_arns" {
  description = "ARNs of the created GitHub Actions roles"
  value = {
    for k, v in aws_iam_role.github_actions : k => v.arn
  }
}

output "state_bucket_names" {
  description = "Names of the created S3 buckets for Terraform state"
  value = {
    for k, v in aws_s3_bucket.terraform_state : k => v.id
  }
}

output "dynamodb_table_names" {
  description = "Names of the created DynamoDB tables for state locking"
  value = {
    for k, v in aws_dynamodb_table.terraform_lock : k => v.name
  }
}