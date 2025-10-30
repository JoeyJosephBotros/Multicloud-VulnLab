#!/bin/bash

set -e

echo "═══════════════════════════════════════════════════════════"
echo "Multi-Cloud Security Lab - Automated Deployment"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Navigate to terraform directory
cd terraform

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Validate configuration
echo "✓ Validating Terraform configuration..."
terraform validate

# Plan deployment
echo "📋 Planning deployment..."
terraform plan -out=tfplan

# Prompt for confirmation
echo ""
read -p "Deploy lab environment? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Deployment cancelled."
    exit 0
fi

# Apply configuration
echo "🚀 Deploying resources (this will take 3-5 minutes)..."
terraform apply tfplan

# Save outputs
echo "📝 Saving deployment information..."
terraform output -json > ../outputs/terraform-outputs.json
terraform output attack_path > ../outputs/attack-path.txt
terraform output quick_commands > ../outputs/quick-commands.txt

# Display summary
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ DEPLOYMENT COMPLETE!"
echo "═══════════════════════════════════════════════════════════"
echo ""
terraform output attack_start_url
echo ""
echo "📁 Detailed information saved to: outputs/"
echo ""
echo "⚠️  IMPORTANT: Run './cleanup.sh' when done to avoid charges!"
echo ""

