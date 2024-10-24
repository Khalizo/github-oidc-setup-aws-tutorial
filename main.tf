resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  
  client_id_list = [
    "sts.amazonaws.com"
  ]
  
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "aws_iam_role" "github_actions" {
  for_each = var.projects

  name = "github-actions-${each.key}-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" : ["repo:${each.value.github_repo}:*"]
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    {
      Environment = var.environment
      Terraform   = "true"
      GithubRepo  = each.value.github_repo
    },
    each.value.additional_tags
  )
}

# Create S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  for_each = var.projects
  bucket   = "${var.environment}-${replace(each.key, "_", "-")}-terraform-state"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  for_each = var.projects
  bucket   = aws_s3_bucket.terraform_state[each.key].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Create DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_lock" {
  for_each      = var.projects
  name          = "terraform-lock-${each.key}-${var.environment}"  # Added environment to make it unique
  billing_mode  = "PAY_PER_REQUEST"
  hash_key      = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "terraform-lock-${each.key}"
    Environment = var.environment
  }
}

# Add custom policies if specified
resource "aws_iam_role_policy" "custom_policy" {
  for_each = {
    for k, v in var.projects : k => v
    if v.custom_policy != ""
  }
  
  name = "custom-policy-${each.key}-${var.environment}"  # Added environment to make it unique
  role = aws_iam_role.github_actions[each.key].id
  policy = each.value.custom_policy
}