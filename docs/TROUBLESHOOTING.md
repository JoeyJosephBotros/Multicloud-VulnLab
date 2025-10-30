# Troubleshooting Guide

Complete guide for resolving common issues during deployment and testing.

## Terraform Issues

### Error: State lock
Cause: Previous Terraform operation was interrupted

Solution:
cd terraform
terraform force-unlock LOCK-ID

### Error: Invalid provider configuration
Cause: Missing or incorrect cloud credentials

Solution:
aws sts get-caller-identity
az account show
source ~/.azure/credentials

### Error: S3 bucket already exists
Cause: S3 bucket names must be globally unique

Solution:
nano terraform/terraform.tfvars
Change: lab_name = "multicloud-lab-yourname123"
terraform apply

### Lambda function creation failed
Cause: IAM role propagation delay

Solution:
sleep 30
cd terraform
terraform apply

## AWS Issues

### AccessDenied when creating IAM resources
Cause: Insufficient permissions on your AWS user

Solution: Your AWS user needs AdministratorAccess or these permissions:
- iam:CreateUser
- iam:CreateRole
- iam:CreatePolicy
- iam:AttachUserPolicy
- s3:CreateBucket
- lambda:CreateFunction

### Cannot access public S3 bucket
Solution:
BUCKET_NAME="multicloud-lab-public-XXXX"
aws s3api get-public-access-block --bucket $BUCKET_NAME
aws s3api get-bucket-policy --bucket $BUCKET_NAME
curl https://${BUCKET_NAME}.s3.amazonaws.com/config/database-config.json

### Invalid AWS credentials
Solution:
aws configure --profile multicloud-lab
aws sts get-caller-identity --profile multicloud-lab

## Azure Issues

### Authorization failed when creating resources
Solution:
az ad sp show --id $ARM_CLIENT_ID
az role assignment list --assignee $ARM_CLIENT_ID --output table

If missing, create service principal:
az ad sp create-for-rbac --name "multicloud-lab-terraform" --role="Contributor" --scopes="/subscriptions/$ARM_SUBSCRIPTION_ID"

### Storage account name already exists
Solution:
lab_name = "mclabunique$(date +%s)"
terraform destroy
terraform apply

### Cannot access Azure blob - 403 Forbidden
Solution:
STORAGE_NAME="mclabpubXXXX"
az storage account show --name $STORAGE_NAME --query allowBlobPublicAccess
az storage container show --name public-backups --account-name $STORAGE_NAME --query publicAccess

### Azure CLI session expired
Solution:
az login
az account set --subscription "Your Subscription Name"
az account show

## CLI Configuration Issues

### AWS CLI not using correct profile
Solution:
aws s3 ls --profile multicloud-lab
OR
export AWS_PROFILE=multicloud-lab

### Azure CLI authentication timeout
Solution:
az login --use-device-code

## Attack Simulation Issues

### Cannot download AWS credentials from Azure blob
Solution:
cd terraform
terraform output attack_start_url
curl -v "URL-HERE"
az storage blob list --account-name storagename --container-name public-backups --auth-mode login

### IAM privilege escalation fails
Solution:
aws iam get-user-policy --user-name multicloud-lab-user --policy-name multicloud-lab-vulnerable-policy --profile compromised
cd terraform
terraform apply -replace=aws_iam_user_policy.vulnerable_user_policy

### Cannot access Lambda environment variables
Solution:
aws lambda list-functions --profile compromised
aws iam get-user-policy --user-name multicloud-lab-user --policy-name multicloud-lab-vulnerable-policy

## Debugging Commands

### Check Terraform State
cd terraform
terraform show
terraform state list
terraform state show aws_s3_bucket.public_bucket

### Verify AWS Resources
aws s3 ls
aws iam list-users --query 'Users[].UserName'
aws lambda list-functions --query 'Functions[].FunctionName'
aws sts get-caller-identity

### Verify Azure Resources
az group list --output table
az storage account list --output table
az storage blob list --account-name NAME --container-name CONTAINER --auth-mode login

### View Terraform Outputs
cd terraform
terraform output
terraform output attack_start_url
terraform output -json > ../outputs/terraform-outputs.json

### Enable Debug Logging
export TF_LOG=DEBUG
terraform apply
aws s3 ls --debug
az storage account list --debug

## Complete Reset
If everything is broken:

./scripts/cleanup.sh
rm -rf terraform/.terraform
rm -f terraform/.terraform.lock.hcl
rm -f terraform/terraform.tfstate*
rm -f terraform/lambda_function.zip
./scripts/verify-setup.sh
./scripts/deploy.sh

## Common Errors Reference

| Error Message | Cause | Fix |
|--------------|-------|-----|
| BucketAlreadyExists | S3 name collision | Change lab_name |
| AccessDenied | Insufficient IAM | Use admin account |
| InvalidAccessKeyId | Wrong AWS creds | Run aws configure |
| AuthorizationFailed | Azure SP lacks perms | Check service principal |
| state lock | Interrupted Terraform | Run terraform force-unlock |

