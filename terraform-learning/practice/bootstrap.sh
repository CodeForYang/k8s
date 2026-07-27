#!/bin/bash
# bootstrap.sh —— 初始化 Terraform 远程 State 存储
# 使用方法：bash bootstrap.sh <你的桶名> [区域]
# 示例：    bash bootstrap.sh edward-tfstate ap-northeast-1

set -euo pipefail

BUCKET="${1:?请传入 S3 桶名，如 edward-tfstate}"
REGION="${2:-ap-northeast-1}"

echo "=== 1/3 创建 S3 桶（桶名需全局唯一）==="
aws s3 mb "s3://${BUCKET}" --region "$REGION"

echo "=== 2/3 启用版本控制 ==="
aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

echo "=== 3/3 启用服务端加密 ==="
aws s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

echo "✅ 完成！在 backend.tf 中写入："
echo "─────────────────────────────"
echo "  bucket = \"${BUCKET}\""
echo "  region = \"${REGION}\""
echo "  use_lockfile = true"
echo "─────────────────────────────"