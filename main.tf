# main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  
  # ВИМКНУТИ всі перевірки аутентифікації
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  
  # Fake endpoints для уникнення реальних AWS викликів
  endpoints {
    s3 = "http://localhost:4566"  # LocalStack endpoint
  }
}

variable "grafana_iam_role_arn" {
  type    = string
  default = "arn:aws:iam::123456789012:role/dummy-role"
}

# Генерувати унікальний суфікс для імені bucket
resource "random_id" "suffix" {
  byte_length = 4
}

# Створити S3 bucket
resource "aws_s3_bucket" "grafana_backups" {
  bucket = "grafana-backups-${random_id.suffix.hex}"

  tags = {
    Name = "grafana-backups-bucket"
  }
}

# Політика доступу до S3 bucket
data "aws_iam_policy_document" "bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [var.grafana_iam_role_arn]
    }
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.grafana_backups.arn
    ]
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = [var.grafana_iam_role_arn]
    }
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.grafana_backups.arn}/*"
    ]
  }
}

# Застосувати політику до bucket
resource "aws_s3_bucket_policy" "grafana_policy" {
  bucket = aws_s3_bucket.grafana_backups.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

# Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket for Grafana backups"
  value       = aws_s3_bucket.grafana_backups.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.grafana_backups.arn
}