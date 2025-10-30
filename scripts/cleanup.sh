#!/bin/bash

set -e

echo "═══════════════════════════════════════════════════════════"
echo "Multi-Cloud Lab - Cleanup Script"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "⚠️  WARNING: This will delete ALL lab resources!"
echo ""

# Prompt for confirmation
read -p "Are you sure you want to destroy the lab? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "🗑️  Destroying resources..."
echo ""

# Method 1: If deployed with Terraform
if [ -d "terraform" ] && [ -f "terraform/terraform.tfstate" ]; then
    echo "Detected Terraform deployment. Using Terraform destroy..."
    cd terraform
    terraform destroy -auto-approve
    cd ..
    echo "✓ Terraform resources destroyed"
else
    # Method 2: Manual cleanup
    echo "Manual cleanup mode..."
    
    # Cleanup AWS resources
    echo ""
    echo "Cleaning up AWS resources..."
    
    # Delete Lambda function
    aws lambda delete-function --function-name multicloud-lab-cross-cloud-processor 2>/dev/null || true
    
    # Delete Lambda IAM role
    aws iam detach-role-policy --role-name multicloud-lab-lambda-role \
      --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess 2>/dev/null || true
    aws iam detach-role-policy --role-name multicloud-lab-lambda-role \
      --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole 2>/dev/null || true
    aws iam delete-role --role-name multicloud-lab-lambda-role 2>/dev/null || true
    
    # Delete S3 bucket (first empty it)
    BUCKET_NAME=$(aws s3 ls | grep multicloud-lab-public | awk '{print $3}')
    if [ -n "$BUCKET_NAME" ]; then
        aws s3 rm s3://$BUCKET_NAME --recursive
        aws s3 rb s3://$BUCKET_NAME
        echo "  ✓ Deleted S3 bucket: $BUCKET_NAME"
    fi
    
    # Delete IAM users
    # First delete access keys
    aws iam list-access-keys --user-name multicloud-lab-user --query 'AccessKeyMetadata[].AccessKeyId' --output text | \
      xargs -I {} aws iam delete-access-key --user-name multicloud-lab-user --access-key-id {} 2>/dev/null || true
    
    # Delete user policies
    aws iam delete-user-policy --user-name multicloud-lab-user \
      --policy-name multicloud-lab-vulnerable-policy 2>/dev/null || true
    
    # Detach admin policy
    aws iam detach-user-policy --user-name multicloud-lab-admin \
      --policy-arn arn:aws:iam::aws:policy/AdministratorAccess 2>/dev/null || true
    
    # Delete users
    aws iam delete-user --user-name multicloud-lab-user 2>/dev/null || true
    aws iam delete-user --user-name multicloud-lab-admin 2>/dev/null || true
    
    echo "✓ AWS resources cleaned up"
    
    # Cleanup Azure resources
    echo ""
    echo "Cleaning up Azure resources..."
    
    az group delete --name multicloud-lab-rg --yes --no-wait 2>/dev/null || true
    
    echo "✓ Azure resource group deletion initiated (runs in background)"
fi

# Cleanup local files
echo ""
echo "Cleaning up local files..."
rm -f terraform/terraform.tfstate*
rm -f terraform/.terraform.lock.hcl
rm -rf terraform/.terraform
rm -f terraform/lambda_function.zip
rm -f outputs/*
rm -f lambda-function.zip
rm -rf lambda-package

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ CLEANUP COMPLETE"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Azure resource deletion may take 5-10 minutes to complete."
echo "You can verify deletion with: az group list"
echo ""

