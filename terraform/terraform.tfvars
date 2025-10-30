# Multi-Cloud Lab - Variable Values
# IMPORTANT: Never commit sensitive data in real usage!

# General Configuration
lab_name    = "multicloudlab"
environment = "testing"

# AWS Configuration
aws_region  = "us-east-1"
aws_profile = "default"  # Leave empty if using environment variables

# Azure Configuration (replace placeholders with actual secure methods)
azure_subscription_id = "your-azure-subscription-id"
azure_client_id       = "your-azure-client-id"
azure_client_secret   = "var.azure_client_secret"  # Provide via secure environment or secret manager
azure_tenant_id       = "your-azure-tenant-id"
azure_location        = "eastus"

# Realistic Data (non-sensitive dummy data)
fake_company_name   = "TechCorp Solutions"
fake_database_host  = "prod-db-primary.us-east-1.rds.amazonaws.com"
fake_api_endpoint   = "https://api.techcorp-solutions.com"

