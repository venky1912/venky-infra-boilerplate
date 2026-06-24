#!/bin/bash
set -euo pipefail

ENV=${1:?"Usage: $0 <environment> [region]"}
REGION=${2:-"eu-west-1"}
PROJECT=$(grep -m1 'project_name' environments/${ENV}/terraform.tfvars.example 2>/dev/null | cut -d'"' -f2 || echo "my-platform")
BUCKET="${PROJECT}-tfstate-${ENV}"
TABLE="${PROJECT}-tflock-${ENV}"

echo "Creating Terraform state backend for: ${ENV}"
echo "  Bucket: ${BUCKET}"
echo "  Table:  ${TABLE}"
echo "  Region: ${REGION}"
echo ""

# Create S3 bucket
aws s3api create-bucket \
  --bucket "${BUCKET}" \
  --region "${REGION}" \
  --create-bucket-configuration LocationConstraint="${REGION}" \
  2>/dev/null || echo "Bucket already exists"

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket "${BUCKET}" \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket "${BUCKET}" \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "aws:kms"}}]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket "${BUCKET}" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Create DynamoDB table
aws dynamodb create-table \
  --table-name "${TABLE}" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "${REGION}" \
  2>/dev/null || echo "Table already exists"

echo ""
echo "✅ Backend ready. Update environments/${ENV}/versions.tf with:"
echo ""
echo "  backend \"s3\" {"
echo "    bucket         = \"${BUCKET}\""
echo "    key            = \"infra/terraform.tfstate\""
echo "    region         = \"${REGION}\""
echo "    dynamodb_table = \"${TABLE}\""
echo "    encrypt        = true"
echo "  }"
