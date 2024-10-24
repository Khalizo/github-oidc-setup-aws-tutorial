projects = {
  myproject = {
    github_repo = "your-username/your-project-name"
    additional_tags = {
      Project = "MyProject"
    }
    custom_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::dev-myproject-terraform-state",
        "arn:aws:s3:::dev-myproject-terraform-state/*",
        "arn:aws:s3:::prod-myproject-terraform-state",
        "arn:aws:s3:::prod-myproject-terraform-state/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/terraform-lock-myproject-*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "s3:*",
        "rds:*",
        "iam:*",
        "elasticloadbalancing:*",
        "autoscaling:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
  }
}