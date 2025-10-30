# Multi-Cloud Lab - Variables
# Configure these in terraform.tfvars

# ============================================================================
# General Configuration
# ============================================================================

variable "lab_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "multicloud-lab"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "testing"
}

# ============================================================================
# AWS Configuration
# ============================================================================

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile name (optional)"
  type        = string
  default     = ""
}

# ============================================================================
# Azure Configuration
# ============================================================================

variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "azure_client_id" {
  description = "Azure Service Principal Client ID"
  type        = string
  sensitive   = true
}

variable "azure_client_secret" {
  description = "Azure Service Principal Client Secret"
  type        = string
  sensitive   = true
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  sensitive   = true
}

variable "azure_location" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "eastus"
}

# ============================================================================
# Realistic Data Configuration
# ============================================================================

variable "fake_company_name" {
  description = "Fake company name for realistic data"
  type        = string
  default     = "TechCorp Solutions"
}

variable "fake_database_host" {
  description = "Fake database hostname"
  type        = string
  default     = "prod-db-primary.us-east-1.rds.amazonaws.com"
}

variable "fake_api_endpoint" {
  description = "Fake API endpoint"
  type        = string
  default     = "https://api.techcorp-solutions.com"
}

