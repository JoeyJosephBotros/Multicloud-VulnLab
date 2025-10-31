# Multi-Cloud Security Lab
A Cross-Cloud Vulnerable Attack Scenario

A deliberately vulnerable multi-cloud environment for security testing and demonstration purposes.

## WARNING
This lab creates intentionally vulnerable resources. Only deploy in isolated test accounts. Never use production credentials or accounts.

## Required Knowledge
- Basic understanding of cloud computing concepts
- Familiarity with command-line interface
- Understanding of IAM, storage services, and serverless computing
- Basic penetration testing knowledge

---

## Lab Overview

Scenario: Cross-Cloud Credential Exposure
Resources: 8 total (3 Azure + 5 AWS)
Cost: ~$5 for 2-3 days
Demo Time: 10-12 minutes

### Attack Path
1. Public Azure Storage → AWS credentials
2. AWS low-privilege access → Lambda enumeration
3. Lambda env vars → Azure Storage credentials
4. Azure private storage → sensitive data
5. IAM privilege escalation → AWS admin access

## Quick Start

### Prerequisites
- AWS account with billing enabled
- Azure account with active subscription
- AWS CLI installed and configured
- Azure CLI installed and authenticated
- Terraform >= 1.0

## Cloud Account Setup
### Step 1: AWS Account Setup

#### 1.1 Create AWS Account
1. Visit [https://aws.amazon.com](https://aws.amazon.com)
2. Click "Create an AWS Account"
3. Follow the registration process
4. Add a payment method (required, but free tier available)
5. Verify your phone number
6. Choose "Basic Support - Free"

#### 1.2 Create IAM User for Terraform

**Why?** Never use root credentials for Terraform. Create a dedicated IAM user.

1. **Login to AWS Console**
   - Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
   - Sign in with your root account

2. **Navigate to IAM**
   - Search for "IAM" in the top search bar
   - Click on "IAM" service

3. **Create IAM User**
   IAM → Users → Create user

   User name: terraform-deployer
   ☑ Provide user access to the AWS Management Console (optional)
   ☐ Users must create a new password at next sign-in

   Click: Next
 

4. **Attach Permissions**
   ☑ Attach policies directly

   Search and select:
   - AdministratorAccess (for lab deployment only)

   Click: Next
   Click: Create user

5. **Create Access Keys**
 
   Click on the newly created user
   → Security credentials tab
   → Access keys
   → Create access key

   Use case: Command Line Interface (CLI)
   ☑ I understand the above recommendation

   Click: Next
   Description tag: terraform-lab-deployment
   Click: Create access key

   ⚠️ IMPORTANT: Download .csv file or copy:
   - Access key ID (starts with AKIA...)
   - Secret access key (long random string)

   Click: Done


6. **Save Credentials Securely**
 
---

### Step 2: Azure Account Setup

#### 2.1 Create Azure Account
1. Visit [https://azure.microsoft.com/free](https://azure.microsoft.com/free)
2. Click "Start free"
3. Sign in with Microsoft account (or create one)
4. Verify identity with phone number
5. Add credit card (required, but won't be charged for free credits)
6. Complete registration

**Free Credits:** $200 USD credit for 30 days + 12 months of free services

#### 2.2 Create Service Principal for Terraform

**Why?** Service Principal acts as a non-human identity for Terraform to interact with Azure.

1. **Login to Azure**
   ```
   az login
   ```
   - A browser window will open
   - Sign in with your Azure account
   - Close browser when prompted

2. **Get Your Subscription ID**
   ```
   az account show --query id --output tsv
   ```
   - Copy this ID (format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)
   - Save it as: `SUBSCRIPTION_ID`

3. **Create Service Principal**
   ```
   az ad sp create-for-rbac \
     --name "terraform-multicloud-lab" \
     --role="Contributor" \
     --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"
   ```

   Replace `YOUR_SUBSCRIPTION_ID` with the ID from step 2.

4. **Save the Output**

   The command will output JSON like this:
   ```
   {
     "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
     "displayName": "terraform-multicloud-lab",
     "password": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
     "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
   }
   ```

   **Map these values:**
   - `appId` → `ARM_CLIENT_ID`
   - `password` → `ARM_CLIENT_SECRET`
   - `tenant` → `ARM_TENANT_ID`
   - Your Subscription ID → `ARM_SUBSCRIPTION_ID`

   **Save these securely** - you'll need them later!

---

## 🛠️ Tool Installation

### Step 3: Install Required Tools on Linux

#### 3.1 Update System
```
# Update package lists
sudo apt update && sudo apt upgrade -y
```

#### 3.2 Install Terraform

```
# Download Terraform
wget https://releases.hashicorp.com/terraform/1.6.3/terraform_1.6.3_linux_amd64.zip

# Unzip
unzip terraform_1.6.3_linux_amd64.zip

# Move to bin directory
sudo mv terraform /usr/local/bin/

# Verify installation
terraform --version
```

**Alternative (using package manager):**
```
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

#### 3.3 Install AWS CLI

```
# Download AWS CLI installer
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Unzip
unzip awscliv2.zip

# Install
sudo ./aws/install

# Verify
aws --version
```

#### 3.4 Install Azure CLI

```
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verify
az --version
```

#### 3.5 Install Supporting Tools

```
# Install jq (JSON processor)
sudo apt install jq -y

# Install git
sudo apt install git -y

# Install Python and pip (if not already installed)
sudo apt install python3 python3-pip -y

# Verify installations
jq --version
git --version
python3 --version
```

---


### Step 1: Verify Prerequisites
```
./scripts/verify-setup.sh
```

### Step 2: Configure Credentials
```
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Fill in your Azure credentials:
- azure_subscription_id
- azure_client_id
- azure_client_secret
- azure_tenant_id

### Step 3: Deploy Lab
```
cd ..
./scripts/deploy.sh
```

### Step 4: Run Attack Simulation
```
./scripts/test-attack.sh
```

### Step 5: Cleanup
```
./scripts/cleanup.sh
```

Always cleanup to avoid ongoing charges!

## Vulnerabilities Demonstrated

| ID | Vulnerability | Severity | Cloud |
|----|--------------|----------|-------|
| V-01 | Public Storage Account | Critical | Azure |
| V-02 | Credentials in Public Blob | Critical | Azure |
| V-03 | IAM Privilege Escalation | Critical | AWS |
| V-04 | Hardcoded Credentials in Lambda | High | AWS |
| V-05 | Overprivileged Lambda Role | High | AWS |
| V-06 | Public S3 Bucket | High | AWS |
| V-07 | Missing MFA | Medium | Both |

## Key Takeaways
1. Credential Management: Never hardcode credentials
2. Least Privilege: Avoid privilege escalation paths
3. Public Access: Default to private
4. Cross-Cloud Risk: Credential flows between clouds
5. Detection: Enable comprehensive logging

## Cost Estimation
Approximate costs for 3-day deployment:

| Service | Cost |
|---------|------|
| AWS Lambda | Free tier |
| AWS IAM | Free |
| AWS S3 | <$1 |
| Azure Storage | <$2 |
| Total | ~$5-7 |

## Security Disclaimer
This lab is for educational and authorized security testing only:
- Deploy only in isolated test accounts
- Never use production credentials
- Destroy resources immediately after testing
- Set billing alerts
- Follow responsible disclosure practices

## Support
For issues:
1. Check docs/TROUBLESHOOTING.md
2. Review Terraform logs: export TF_LOG=DEBUG
3. Verify prerequisites: ./scripts/verify-setup.sh
4. Destroy and redeploy: ./scripts/cleanup.sh && ./scripts/deploy.sh

Ready to deploy?
./scripts/verify-setup.sh && ./scripts/deploy.sh

Good luck with your security assessment!

