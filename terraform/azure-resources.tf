# Azure Resource Group
resource "azurerm_resource_group" "lab" {
  name     = "${var.lab_name}-rg"
  location = var.azure_location

  tags = {
    Environment = "Production"
  }
}

# ============================================================================
# Public Storage Account
# ============================================================================

resource "azurerm_storage_account" "public_storage" {
  name                            = "${var.lab_name}pub${random_id.suffix.hex}"
  resource_group_name             = azurerm_resource_group.lab.name
  location                        = azurerm_resource_group.lab.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = true

  tags = {
    Purpose = "Public backup documentation"
  }
}

resource "azurerm_storage_container" "public_backups" {
  name                  = "public-backups"
  storage_account_name  = azurerm_storage_account.public_storage.name
  container_access_type = "container"
}

# Backup script with embedded AWS credentials (MAIN ENTRY POINT)
resource "azurerm_storage_blob" "backup_script" {
  name                   = "backup-sync.sh"
  storage_account_name   = azurerm_storage_account.public_storage.name
  storage_container_name = azurerm_storage_container.public_backups.name
  type                   = "Block"
  content_type           = "text/x-shellscript"
  source_content         = <<EOF
#!/bin/bash
# TechCorp Automated Backup Sync Script
# Description: Syncs Azure backups to AWS S3 for disaster recovery
# Author: DevOps Team
# Last Updated: 2025-08-15
# Version: 2.3.1

# Configuration
BACKUP_DATE=$(date +%Y%m%d)
LOG_FILE="/var/log/backup-sync-$${BACKUP_DATE}.log"
AZURE_CONTAINER="techcorp-backups"
AWS_S3_BUCKET="techcorp-dr-backup"

# AWS Credentials - TODO: Move to AWS Secrets Manager
export AWS_ACCESS_KEY_ID="${aws_iam_access_key.initial_user_key.id}"
export AWS_SECRET_ACCESS_KEY="${aws_iam_access_key.initial_user_key.secret}"
export AWS_DEFAULT_REGION="us-east-1"

# Azure credentials loaded from environment
# Ensure AZURE_STORAGE_ACCOUNT and AZURE_STORAGE_KEY are set

log_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $$1" | tee -a "$$LOG_FILE"
}

check_prerequisites() {
    log_message "Checking prerequisites..."
    if ! command -v aws &> /dev/null; then
        log_message "ERROR: AWS CLI not installed"
        exit 1
    fi
    log_message "Prerequisites check passed"
}

main() {
    log_message "TechCorp Backup Sync - Starting"
    check_prerequisites
    log_message "TechCorp Backup Sync - Completed"
}

main

# Notes:
# - This script runs daily via cron at 2 AM UTC
# - AWS credentials need to be rotated quarterly
# - Last rotated: 2025-08-15
# - Contact: devops-team@techcorp-demo.com for issues
EOF
}

resource "azurerm_storage_blob" "readme" {
  name                   = "README.md"
  storage_account_name   = azurerm_storage_account.public_storage.name
  storage_container_name = azurerm_storage_container.public_backups.name
  type                   = "Block"
  content_type           = "text/markdown"
  source_content         = <<EOF
# TechCorp Backup Documentation

This container holds automation scripts for TechCorp multi-cloud backup procedures.

Files:
- backup-sync.sh - Automated Azure to AWS sync script
- README.md - This documentation

Usage:
Execute the backup script with proper permissions.

Schedule: Runs daily at 02:00 UTC via cron

For issues contact: devops-team@techcorp-demo.com
EOF
}

# ============================================================================
# Private Storage Account
# ============================================================================

resource "azurerm_storage_account" "secrets_storage" {
  name                            = "${var.lab_name}sec${random_id.suffix.hex}"
  resource_group_name             = azurerm_resource_group.lab.name
  location                        = azurerm_resource_group.lab.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false

  tags = {
    Purpose = "Sensitive data storage"
  }
}

resource "azurerm_storage_container" "sensitive_data" {
  name                  = "sensitive-data"
  storage_account_name  = azurerm_storage_account.secrets_storage.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "aws_backup_creds" {
  name                   = "aws-backup-credentials.txt"
  storage_account_name   = azurerm_storage_account.secrets_storage.name
  storage_container_name = azurerm_storage_container.sensitive_data.name
  type                   = "Block"
  content_type           = "text/plain"
  source_content         = <<EOF
TechCorp AWS Backup User Credentials
CONFIDENTIAL - Internal Use Only

[s3-backup-user]
aws_access_key_id = ${aws_iam_access_key.backup_user_key.id}
aws_secret_access_key = ${aws_iam_access_key.backup_user_key.secret}
region = us-east-1

Purpose: S3 backup and disaster recovery operations
Permissions: S3 read access, IAM list users
Last Rotated: 2025-10-01
Next Rotation: 2026-01-01

Usage:
export AWS_ACCESS_KEY_ID="${aws_iam_access_key.backup_user_key.id}"
export AWS_SECRET_ACCESS_KEY="${aws_iam_access_key.backup_user_key.secret}"
aws s3 ls

Emergency Contact: devops-team@techcorp-demo.com
EOF
}

resource "azurerm_storage_blob" "connection_strings" {
  name                   = "connection-strings.json"
  storage_account_name   = azurerm_storage_account.secrets_storage.name
  storage_container_name = azurerm_storage_container.sensitive_data.name
  type                   = "Block"
  content_type           = "application/json"
  source_content         = jsonencode({
    environment = "production"
    last_updated = "2025-10-20"
    
    azure_sql = {
      server   = "techcorp-prod.database.windows.net"
      database = "customer_db"
      username = "sqladmin"
      password = "ComplexP@ssw0rd!2025AzureSQL"
      port     = 1433
    }
    
    cosmos_db = {
      endpoint = "https://techcorp-cosmos.documents.azure.com:443/"
      key      = "C2y6yDjf5R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw"
    }
    
    aws_backup_s3 = {
      note        = "S3 backup credentials in aws-backup-credentials.txt"
      bucket      = aws_s3_bucket.public_bucket.id
      region      = var.aws_region
      username    = "s3-backup-user"
      access_type = "IAM User"
    }
    
    it_support = {
      note     = "IT support credentials stored in AWS S3"
      location = "s3://${aws_s3_bucket.public_bucket.id}/config/aws-accounts.json"
      username = "it-support-user"
      purpose  = "IAM management and infrastructure support"
    }
  })
}

resource "azurerm_storage_blob" "infrastructure_notes" {
  name                   = "infrastructure-notes.txt"
  storage_account_name   = azurerm_storage_account.secrets_storage.name
  storage_container_name = azurerm_storage_container.sensitive_data.name
  type                   = "Block"
  content_type           = "text/plain"
  source_content         = <<EOF
TechCorp Multi-Cloud Infrastructure Notes
Last Updated: 2025-10-20

AWS Account
-----------
Account ID: ${data.aws_caller_identity.current.account_id}
Region: ${var.aws_region}

Service Accounts:
1. multicloudlab-user - Lambda access only
2. s3-backup-user - S3 backup operations
3. it-support-user - IAM management
4. multicloudlab-admin - Full administrator

Azure Account
-------------
Subscription: ${var.azure_subscription_id}
Tenant: ${var.azure_tenant_id}

Storage Accounts:
1. ${azurerm_storage_account.public_storage.name} - Public backups
2. ${azurerm_storage_account.secrets_storage.name} - Private secrets

Cross-Cloud Integration
-----------------------
Lambda function contains Azure credentials in environment variables
Backup sync runs daily at 02:00 UTC

Security Notes
--------------
Rotate credentials quarterly
Review IAM policies monthly
Monitor CloudTrail and Azure logs
Enable MFA for admin accounts

Next Review: Q1 2026
EOF
}

