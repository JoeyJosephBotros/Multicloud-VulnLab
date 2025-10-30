# Multi-Cloud Lab - Provider Configuration
# Supports both AWS and Azure

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

# AWS Provider Configuration
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile  # Optional: use profile from ~/.aws/credentials
  
  # Or use environment variables:
  # AWS_ACCESS_KEY_ID
  # AWS_SECRET_ACCESS_KEY
  
  default_tags {
    tags = {
      Project     = "MultiCloudLab"
      Environment = "Testing"
      ManagedBy   = "Terraform"
      Purpose     = "SecurityTesting"
    }
  }
}

# Azure Provider Configuration
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
  
  # Credentials from environment variables:
  # ARM_SUBSCRIPTION_ID
  # ARM_CLIENT_ID
  # ARM_CLIENT_SECRET
  # ARM_TENANT_ID
  
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

# Random provider for unique naming
provider "random" {}

# Archive provider for Lambda packaging
provider "archive" {}

