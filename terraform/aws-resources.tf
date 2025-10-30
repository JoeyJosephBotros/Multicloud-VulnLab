# Random suffix for unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}

# Get current AWS account details
data "aws_caller_identity" "current" {}

# Archive Lambda function code inline
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"

  source {
    content  = <<-PYTHON
import json
import os
from datetime import datetime

def lambda_handler(event, context):
    azure_storage = os.environ.get('AZURE_STORAGE_ACCOUNT')
    s3_bucket = os.environ.get('S3_BACKUP_BUCKET')
    
    print(f"Processing at {datetime.now().isoformat()}")
    print(f"Azure Storage: {azure_storage}")
    print(f"S3 Bucket: {s3_bucket}")
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Backup processor executed',
            'timestamp': datetime.now().isoformat()
        })
    }
PYTHON
    filename = "handler.py"
  }
}

# ============================================================================
# IAM User 1: multicloudlab-user (Initial Access - Lambda Only)
# ============================================================================

resource "aws_iam_user" "initial_user" {
  name = "${var.lab_name}-user"
  
  tags = {
    Purpose = "Initial access - Lambda enumeration only"
  }
}

resource "aws_iam_user_policy" "initial_policy" {
  name = "${var.lab_name}-initial-policy"
  user = aws_iam_user.initial_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LambdaEnumerationOnly"
        Effect = "Allow"
        Action = [
          "lambda:ListFunctions",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_access_key" "initial_user_key" {
  user = aws_iam_user.initial_user.name
}

# ============================================================================
# IAM User 2: s3-backup-user (Found in Azure - S3 + IAM Enum)
# ============================================================================

resource "aws_iam_user" "backup_user" {
  name = "s3-backup-user"
  
  tags = {
    Purpose = "S3 backup - Found in Azure private storage"
  }
}

resource "aws_iam_user_policy" "backup_policy" {
  name = "S3BackupAccessPolicy"
  user = aws_iam_user.backup_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:ListAllMyBuckets"
        ]
        Resource = [
          aws_s3_bucket.public_bucket.arn,
          "${aws_s3_bucket.public_bucket.arn}/*"
        ]
      },
      {
        Sid    = "IAMBasicEnum"
        Effect = "Allow"
        Action = [
          "iam:ListUsers",
          "iam:GetUser"
        ]
        Resource = "*"
      },
      {
        Sid    = "ViewOwnPolicies"
        Effect = "Allow"
        Action = [
          "iam:ListUserPolicies",
          "iam:ListAttachedUserPolicies",
          "iam:GetUserPolicy"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/s3-backup-user"
      }
    ]
  })
}

resource "aws_iam_access_key" "backup_user_key" {
  user = aws_iam_user.backup_user.name
}

# ============================================================================
# IAM User 3: it-support-user (Found in S3 - Privilege Escalation)
# ============================================================================

resource "aws_iam_user" "support_user" {
  name = "it-support-user"
  
  tags = {
    Purpose = "IT Support - Has privilege escalation capability"
  }
}

resource "aws_iam_user_policy" "support_policy" {
  name = "ITSupportPolicy"
  user = aws_iam_user.support_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "IAMEnumeration"
        Effect = "Allow"
        Action = [
          "iam:ListUsers",
          "iam:GetUser",
          "iam:ListAccessKeys"
        ]
        Resource = "*"
      },
      {
        Sid    = "ViewOwnPolicies"
        Effect = "Allow"
        Action = [
          "iam:ListUserPolicies",
          "iam:ListAttachedUserPolicies",
          "iam:GetUserPolicy"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/it-support-user"
      },
      {
        Sid    = "PrivilegeEscalation"
        Effect = "Allow"
        Action = "iam:CreateAccessKey"
        Resource = aws_iam_user.admin_user.arn
      }
    ]
  })
}

resource "aws_iam_access_key" "support_user_key" {
  user = aws_iam_user.support_user.name
}

# ============================================================================
# IAM User 4: multicloudlab-admin (Escalation Target)
# ============================================================================

resource "aws_iam_user" "admin_user" {
  name = "${var.lab_name}-admin"
  
  tags = {
    Purpose = "Administrator - Target for privilege escalation"
  }
}

resource "aws_iam_user_policy_attachment" "admin_policy" {
  user       = aws_iam_user.admin_user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ============================================================================
# S3 Bucket - Private (Only s3-backup-user can access)
# ============================================================================

resource "aws_s3_bucket" "public_bucket" {
  bucket = "${var.lab_name}-data-${random_id.suffix.hex}"

  tags = {
    Name = "TechCorp Data Bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "public_bucket_pab" {
  bucket = aws_s3_bucket.public_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Policy - Only s3-backup-user can access
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.public_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBackupUserOnly"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_user.backup_user.arn
        }
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = [
          aws_s3_bucket.public_bucket.arn,
          "${aws_s3_bucket.public_bucket.arn}/*"
        ]
      }
    ]
  })
}

# S3 Objects with realistic data
resource "aws_s3_object" "aws_accounts" {
  bucket       = aws_s3_bucket.public_bucket.id
  key          = "config/aws-accounts.json"
  content_type = "application/json"
  content = jsonencode({
    version      = "2.1"
    last_updated = "2025-10-20"
    company      = "TechCorp"
    accounts = {
      production = {
        account_id     = data.aws_caller_identity.current.account_id
        primary_region = var.aws_region
        admin_email    = "aws-admin@techcorp-demo.com"
      }
    }
    service_accounts = {
      it_support = {
        username          = "it-support-user"
        access_key_id     = aws_iam_access_key.support_user_key.id
        secret_access_key = aws_iam_access_key.support_user_key.secret
        purpose           = "Infrastructure support and IAM management"
        created           = "2025-08-15"
        last_rotated      = "2025-10-01"
        permissions       = "IAM read/write, admin delegation"
        notes             = "Has CreateAccessKey on admin for emergency access recovery"
      }
    }
  })
}

resource "aws_s3_object" "database_config" {
  bucket       = aws_s3_bucket.public_bucket.id
  key          = "config/database-config.json"
  content_type = "application/json"
  content = jsonencode({
    environment = "production"
    databases = {
      postgresql = {
        host     = "techcorp-prod.cluster-abc123.us-east-1.rds.amazonaws.com"
        port     = 5432
        database = "techcorp_main"
        username = "dbadmin"
        password = "PgP@ssw0rd!2025SecureDB"
      }
      redis = {
        host     = "techcorp-cache.abc123.cache.amazonaws.com"
        port     = 6379
        password = "RedisSecure!2025Cache"
      }
    }
  })
}

resource "aws_s3_object" "api_config" {
  bucket       = aws_s3_bucket.public_bucket.id
  key          = "config/api-keys.json"
  content_type = "application/json"
  content = jsonencode({
    services = {
      stripe = {
        publishable_key = "pk_live_51Abc123"
        secret_key      = "sk_live_51Xyz789"
      }
      sendgrid = {
        api_key = "SG.Abc123Def456"
      }
      twilio = {
        account_sid = "ACabc123def456"
        auth_token  = "abc123def456ghi"
      }
    }
  })
}

# ============================================================================
# Lambda Function
# ============================================================================

resource "aws_iam_role" "lambda_role" {
  name = "${var.lab_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_s3_full" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_lambda_function" "cross_cloud_processor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.lab_name}-cross-cloud-processor"
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.11"
  timeout          = 60

  environment {
    variables = {
      ENVIRONMENT           = "production"
      LOG_LEVEL             = "INFO"
      AZURE_STORAGE_ACCOUNT = azurerm_storage_account.secrets_storage.name
      AZURE_STORAGE_KEY     = azurerm_storage_account.secrets_storage.primary_access_key
      AZURE_TENANT_ID       = var.azure_tenant_id
      S3_BACKUP_BUCKET      = aws_s3_bucket.public_bucket.id
    }
  }

  tags = {
    Purpose = "Cross-cloud data processor"
  }
}

