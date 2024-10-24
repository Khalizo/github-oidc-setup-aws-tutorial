variable "environment" {
  type        = string
  description = "Environment name (dev/prod)"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "projects" {
  type = map(object({
    github_repo     = string
    additional_tags = optional(map(string), {})
    custom_policy   = optional(string, "")
  }))
  description = "Map of projects and their configurations"
}


