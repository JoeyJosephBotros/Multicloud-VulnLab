output "attack_start_url" {
  description = "Entry point - backup script with embedded credentials"
  value       = "https://${azurerm_storage_account.public_storage.name}.blob.core.windows.net/${azurerm_storage_container.public_backups.name}"
}

output "azure_public_storage" {
  description = "Azure public storage account"
  value       = azurerm_storage_account.public_storage.name
}

output "azure_secrets_storage" {
  description = "Azure private storage account"
  value       = azurerm_storage_account.secrets_storage.name
}

output "aws_s3_bucket" {
  description = "AWS S3 bucket name"
  value       = aws_s3_bucket.public_bucket.id
}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "lab_entry_point" {
  description = "Complete lab entry point information"
  value = <<-EOT
  
  ╔════════════════════════════════════════════════════════════════════════════╗
  ║              TECHCORP MULTI-CLOUD SECURITY ASSESSMENT                      ║
  ║                         Lab Entry Point                                    ║
  ╚════════════════════════════════════════════════════════════════════════════╝
  
  SCENARIO: GitHub Leak Discovery
  ════════════════════════════════════════════════════════════════════════════
  
  During OSINT reconnaissance, you discovered a DELETED commit in TechCorp's
  public GitHub repository containing internal cloud infrastructure documentation.
  
  Repository: techcorp-demos/infrastructure-docs (archived)
  Commit SHA: a7f3b2c9d4e5f6 (deleted September 2025)
  File: docs/cloud-backup-setup.md
  
  LEAKED INFORMATION:
  ────────────────────────────────────────────────────────────────────────────
  
  "For initial development and testing, we've configured a temporary Azure 
  Storage container with public access to facilitate easy team sharing.
  
  Infrastructure Details:
  - Azure Storage Container: https://${azurerm_storage_account.public_storage.name}.blob.core.windows.net/public-backups
  - Access: Container-level public read
  - Purpose: Backup automation scripts and configuration templates
  
  Development Team Note (John Doe - DevOps Lead):
  'I've placed the backup-sync.sh script in the container. Note that it
  currently has AWS credentials hardcoded for our testing phase. This is
  temporary until we migrate to proper secret management systems.'
  
  Migration Timeline: Q4 2025 (Currently in development phase)"
  
  YOUR MISSION:
  ════════════════════════════════════════════════════════════════════════════
  
  1. Enumerate the exposed Azure Storage container
  2. Identify and extract embedded credentials
  3. Pivot to AWS using discovered credentials
  4. Enumerate cloud resources and permissions
  5. Execute lateral movement between clouds
  6. Escalate privileges to administrator access
  7. Document complete attack chain and business impact
  
  TECHNICAL DETAILS:
  ────────────────────────────────────────────────────────────────────────────
  
  Azure Storage Account: ${azurerm_storage_account.public_storage.name}
  Container Name: public-backups
  Container URL: https://${azurerm_storage_account.public_storage.name}.blob.core.windows.net/public-backups
  
  Key File: backup-sync.sh (contains embedded AWS credentials)
  
  AWS Account ID: ${data.aws_caller_identity.current.account_id}
  AWS Region: us-east-1
  
  ATTACK CHAIN OVERVIEW:
  ────────────────────────────────────────────────────────────────────────────
  
  Step 1: Azure Public Storage → Download backup-sync.sh
          ↓ Extract: multicloudlab-user AWS credentials
  
  Step 2: AWS Lambda Enumeration → Extract Azure private storage credentials
          ↓ Pivot: Access Azure private storage (sensitive-data container)
  
  Step 3: Azure Private Storage → Download aws-backup-credentials.txt
          ↓ Extract: s3-backup-user credentials
  
  Step 4: AWS S3 Access → Download config/aws-accounts.json
          ↓ Extract: it-support-user credentials
  
  Step 5: AWS IAM Enumeration → Discover CreateAccessKey permission
          ↓ Exploit: Create access keys for multicloudlab-admin
  
  Step 6: AWS Administrator → Complete cloud compromise achieved
  
  SCOPE:
  ────────────────────────────────────────────────────────────────────────────
  ✓ In Scope: Azure ${azurerm_storage_account.public_storage.name}*, AWS ${data.aws_caller_identity.current.account_id}
  ✗ Out of Scope: DoS attacks, data destruction, social engineering
  
  FIRST STEP:
  ────────────────────────────────────────────────────────────────────────────
  
  Enumerate the Azure container to discover files (no authentication needed):
  
  curl "https://${azurerm_storage_account.public_storage.name}.blob.core.windows.net/public-backups?restype=container&comp=list"
  
  ════════════════════════════════════════════════════════════════════════════
  
  Save the full engagement brief: See ENTRY-POINT.md in the docs folder
  
  Good luck with your assessment!
  
  EOT
}

