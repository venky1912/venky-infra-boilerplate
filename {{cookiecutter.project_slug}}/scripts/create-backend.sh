#!/bin/bash
set -euo pipefail
ENV=${1:?"Usage: $0 <dev|staging|prod>"}
REGION="{{ cookiecutter.aws_region }}"
BUCKET="{{ cookiecutter.project_slug }}-tfstate-${ENV}"
TABLE="{{ cookiecutter.project_slug }}-tflock-${ENV}"
echo "Creating state backend: ${BUCKET} / ${TABLE}"
aws s3api create-bucket --bucket "${BUCKET}" --region "${REGION}" --create-bucket-configuration LocationConstraint="${REGION}" 2>/dev/null || echo "Bucket exists"
aws s3api put-bucket-versioning --bucket "${BUCKET}" --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket "${BUCKET}" --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms"}}]}'
aws s3api put-public-access-block --bucket "${BUCKET}" --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
aws dynamodb create-table --table-name "${TABLE}" --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region "${REGION}" 2>/dev/null || echo "Table exists"
echo "Done"
