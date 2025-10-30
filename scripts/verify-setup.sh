#!/bin/bash

echo "═══════════════════════════════════════════════════════════"
echo "Multi-Cloud Lab - Prerequisites Check"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

# Check AWS CLI
echo -n "Checking AWS CLI... "
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>&1 | cut -d' ' -f1)
    echo -e "${GREEN}✓ $AWS_VERSION${NC}"
else
    echo -e "${RED}✗ Not installed${NC}"
    echo "  Install: https://aws.amazon.com/cli/"
    ERRORS=$((ERRORS+1))
fi

# Check AWS credentials
echo -n "Checking AWS credentials... "
if aws sts get-caller-identity &> /dev/null; then
    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    echo -e "${GREEN}✓ Configured (Account: $AWS_ACCOUNT)${NC}"
else
    echo -e "${RED}✗ Not configured${NC}"
    echo "  Run: aws configure"
    ERRORS=$((ERRORS+1))
fi

# Check Azure CLI
echo -n "Checking Azure CLI... "
if command -v az &> /dev/null; then
    AZ_VERSION=$(az --version 2>&1 | head -1 | cut -d' ' -f2)
    echo -e "${GREEN}✓ azure-cli $AZ_VERSION${NC}"
else
    echo -e "${RED}✗ Not installed${NC}"
    echo "  Install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    ERRORS=$((ERRORS+1))
fi

# Check Azure authentication
echo -n "Checking Azure authentication... "
if az account show &> /dev/null; then
    AZ_SUBSCRIPTION=$(az account show --query name --output tsv)
    echo -e "${GREEN}✓ Authenticated (Subscription: $AZ_SUBSCRIPTION)${NC}"
else
    echo -e "${RED}✗ Not authenticated${NC}"
    echo "  Run: az login"
    ERRORS=$((ERRORS+1))
fi

# Check Terraform
echo -n "Checking Terraform... "
if command -v terraform &> /dev/null; then
    TF_VERSION=$(terraform --version | head -1)
    echo -e "${GREEN}✓ $TF_VERSION${NC}"
else
    echo -e "${RED}✗ Not installed${NC}"
    echo "  Install: https://www.terraform.io/downloads"
    ERRORS=$((ERRORS+1))
fi

# Check jq (for JSON parsing)
echo -n "Checking jq... "
if command -v jq &> /dev/null; then
    JQ_VERSION=$(jq --version)
    echo -e "${GREEN}✓ $JQ_VERSION${NC}"
else
    echo -e "${YELLOW}⚠ Not installed (optional)${NC}"
    echo "  Install: brew install jq (macOS) or apt install jq (Linux)"
fi

# Check curl
echo -n "Checking curl... "
if command -v curl &> /dev/null; then
    echo -e "${GREEN}✓ Installed${NC}"
else
    echo -e "${RED}✗ Not installed${NC}"
    ERRORS=$((ERRORS+1))
fi

# Check Azure environment variables
echo ""
echo "Checking Azure environment variables:"
echo -n "  ARM_SUBSCRIPTION_ID... "
if [ -n "$ARM_SUBSCRIPTION_ID" ]; then
    echo -e "${GREEN}✓ Set${NC}"
else
    echo -e "${YELLOW}⚠ Not set (will use terraform.tfvars)${NC}"
fi

echo -n "  ARM_CLIENT_ID... "
if [ -n "$ARM_CLIENT_ID" ]; then
    echo -e "${GREEN}✓ Set${NC}"
else
    echo -e "${YELLOW}⚠ Not set (will use terraform.tfvars)${NC}"
fi

echo -n "  ARM_CLIENT_SECRET... "
if [ -n "$ARM_CLIENT_SECRET" ]; then
    echo -e "${GREEN}✓ Set${NC}"
else
    echo -e "${YELLOW}⚠ Not set (will use terraform.tfvars)${NC}"
fi

echo -n "  ARM_TENANT_ID... "
if [ -n "$ARM_TENANT_ID" ]; then
    echo -e "${GREEN}✓ Set${NC}"
else
    echo -e "${YELLOW}⚠ Not set (will use terraform.tfvars)${NC}"
fi

# Check terraform.tfvars exists
echo ""
echo -n "Checking terraform.tfvars... "
if [ -f "terraform/terraform.tfvars" ]; then
    echo -e "${GREEN}✓ Exists${NC}"
    
    # Check if placeholder values are still present
    if grep -q "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" terraform/terraform.tfvars; then
        echo -e "  ${RED}⚠ WARNING: Contains placeholder values!${NC}"
        echo "  Edit terraform/terraform.tfvars with your actual Azure credentials"
        ERRORS=$((ERRORS+1))
    fi
else
    echo -e "${RED}✗ Not found${NC}"
    echo "  Copy terraform/terraform.tfvars.example to terraform/terraform.tfvars"
    ERRORS=$((ERRORS+1))
fi

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ All prerequisites met! Ready to deploy.${NC}"
    echo ""
    echo "Run: ./scripts/deploy.sh"
else
    echo -e "${RED}❌ Found $ERRORS error(s). Please fix before deploying.${NC}"
    exit 1
fi
echo "═══════════════════════════════════════════════════════════"

