# GitHub OIDC Setup Tutorial for AWS

This tutorial shows how to set up OpenID Connect (OIDC) authentication between GitHub Actions and AWS, enabling secure, passwordless deployments to multiple AWS environments.

## What You'll Learn

- How to set up OIDC authentication between GitHub Actions and AWS
- How to manage multiple environments (dev/prod) securely
- How to handle Terraform state management across environments
- Best practices for secure CI/CD with AWS

## Prerequisites

- AWS CLI installed locally
- AWS accounts for dev and prod environments
- AWS SSO access configured
- Terraform installed locally (v1.7.0 or later)
- A GitHub repository where you'll deploy infrastructure

## Initial Setup

1. **Configure AWS SSO Profiles**

```bash
# Configure AWS SSO for development account
aws configure sso
# Enter:
# - SSO start URL: your-sso-url
# - SSO Region: your-region
# - Profile name: dev-myproject
# Choose the development account and appropriate role

# Repeat for production account
aws configure sso
# Use profile name: prod-myproject
```

2. **Clone and Configure Repository**

```bash
git clone git@github.com:your-username/github-oidc-setup.git
cd github-oidc-setup
```

3. **Update Configuration**

In `projects/myproject.tfvars`, update:
```hcl
projects = {
  myproject = {
    github_repo = "YourGitHubUsername/your-project-name"  # Update this
    additional_tags = {
      Project = "MyProject"
    }
    # Rest of the configuration remains the same
  }
}
```

## Deployment Steps

### Deploy to Development

```bash
# Login to AWS SSO
aws sso login --profile dev-myproject

# Verify correct account
aws sts get-caller-identity --profile dev-myproject

# Set profile
export AWS_PROFILE=dev-myproject

# Initialize and apply
terraform init
terraform apply -var-file=environments/dev.tfvars -var-file=projects/myproject.tfvars
```

### Deploy to Production

```bash
# Remove state files to avoid conflicts
rm -rf .terraform* terraform.tfstate*

# Login to AWS SSO for prod
aws sso login --profile prod-myproject

# Verify correct account
aws sts get-caller-identity --profile prod-myproject

# Set profile
export AWS_PROFILE=prod-myproject

# Initialize and apply
terraform init
terraform apply -var-file=environments/prod.tfvars -var-file=projects/myproject.tfvars
```

## Setting Up GitHub Actions Workflows

After completing the OIDC setup, you'll need to create GitHub Actions workflows in your main project repository where you'll be deploying infrastructure.

### Example Workflow Files

Check the `example-workflow-files` directory in this repository for complete examples of:
- `terraform-plan.yml` - Runs Terraform plan on pull requests
- `terraform-apply.yml` - Applies Terraform changes on merge

### Implementation Steps

1. **Create Workflow Directory in Your Project**
```bash
mkdir -p .github/workflows
```

2. **Copy and Configure Workflows**
```bash
# Copy example workflow files
cp example-workflow-files/*.yml .github/workflows/

# Update the following in both files:
- YOUR_DEV_ACCOUNT_ID with your dev AWS account ID
- YOUR_PROD_ACCOUNT_ID with your prod AWS account ID
- myproject with your actual project name
```

3. **Directory Structure**
Your project repository should look like this:
```
your-project/
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml
│       └── terraform-apply.yml
└── terraform/
    ├── environments/
    │   ├── dev.tfvars
    │   └── prod.tfvars
    ├── main.tf
    └── [other terraform files]
```

4. **Workflow Behavior**
- Pull requests to `develop` → Terraform plan for dev environment
- Pull requests to `main` → Terraform plan for prod environment
- Merge to `develop` → Terraform apply to dev environment
- Merge to `main` → Terraform apply to prod environment

5. **Required GitHub Setup**
- Create environments: `dev` and `prod`
- Set up branch protection rules
- Configure environment protection rules
- Add required reviewers for production

### Testing the Setup

1. **Test Development Workflow**
```bash
# Create feature branch
git checkout -b feature/test-infrastructure

# Make changes to terraform files
git add .
git commit -m "test: add test infrastructure"
git push origin feature/test-infrastructure

# Create PR to develop branch
```

2. **Test Production Workflow**
```bash
# Create release branch from develop
git checkout develop
git pull
git checkout -b release/test-infrastructure

# Create PR to main branch
```

- Ensure role trust relationships are correct

## Troubleshooting Guide

### Common Issues

1. **OIDC Provider Already Exists**
```bash
# List providers
aws iam list-open-id-connect-providers

# Delete if needed
aws iam delete-open-id-connect-provider --open-id-connect-provider-arn PROVIDER_ARN
```

2. **State File Conflicts**
```bash
# Always clean state when switching accounts
rm -rf .terraform* terraform.tfstate*
```

3. **Access Denied Errors**
- Verify correct AWS profile
- Check SSO session validity
- Confirm admin permissions

### Verification Steps

1. **Verify OIDC Provider**
```bash
aws iam list-open-id-connect-providers
```

2. **Check IAM Roles**
```bash
aws iam get-role --role-name github-actions-myproject-dev
aws iam get-role --role-name github-actions-myproject-prod
```

3. **Check S3 Buckets**
```bash
aws s3 ls | grep myproject-terraform-state
```

## Resources Created

This setup creates in each account:

1. OIDC Provider for GitHub Actions
2. IAM Role for GitHub Actions
3. S3 Bucket for Terraform state
4. DynamoDB Table for state locking

## Next Steps

After deployment:

1. Get the Role ARNs:
```bash
# Development Role ARN
aws iam get-role --role-name github-actions-myproject-dev --query 'Role.Arn' --output text

# Production Role ARN
aws iam get-role --role-name github-actions-myproject-prod --query 'Role.Arn' --output text
```

2. Use these ARNs in your GitHub Actions workflows

## Important Notes

- Always remove state files when switching accounts
- Verify AWS SSO session before running Terraform
- Double-check AWS profile before applying
- OIDC provider is unique per AWS account
- S3 bucket names must be globally unique

## Security Best Practices

- OIDC is more secure than storing AWS credentials in GitHub
- IAM roles are restricted to specific repositories
- State files are stored in environment-specific S3 buckets
- DynamoDB provides state locking

## Files to Update

When using this tutorial, update these files with your project name:

1. `projects/myproject.tfvars` - Update GitHub repository name
2. `.github/workflows/*.yml` - Update role names and bucket names
3. `environments/*.tfvars` - Update environment-specific variables

## Getting Help

If you encounter issues:
1. Check the Troubleshooting Guide above
2. Verify AWS credentials and permissions
3. Check GitHub Actions logs
4. Ensure all placeholders are replaced with your actual values

Would you like me to also provide the updated versions of all the other files in the repository?