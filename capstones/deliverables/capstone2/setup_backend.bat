@echo off
SET BUCKET_NAME=iac-capstone-tfstate-justo
SET TABLE_NAME=iac-capstone-tfstate-lock
SET REGION=us-east-1

echo [1/4] Creating S3 Bucket: %BUCKET_NAME%...
aws s3api create-bucket --bucket %BUCKET_NAME% --region %REGION%
if %ERRORLEVEL% NEQ 0 (
    echo Error creating bucket. It might already exist or name is taken.
)

echo [2/4] Enabling Versioning...
aws s3api put-bucket-versioning --bucket %BUCKET_NAME% --versioning-configuration Status=Enabled

echo [3/4] Enabling Server-Side Encryption...
aws s3api put-bucket-encryption --bucket %BUCKET_NAME% --server-side-encryption-configuration "{\"Rules\":[{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\":\"AES256\"}}]}"

echo [4/4] Creating DynamoDB Lock Table: %TABLE_NAME%...
aws dynamodb create-table ^
  --table-name %TABLE_NAME% ^
  --attribute-definitions AttributeName=LockID,AttributeType=S ^
  --key-schema AttributeName=LockID,KeyType=HASH ^
  --billing-mode PAY_PER_REQUEST
if %ERRORLEVEL% NEQ 0 (
    echo Table might already exist.
)

echo.
echo ============================================
echo Setup Complete for Justo!
echo Bucket: %BUCKET_NAME%
echo Table:  %TABLE_NAME%
echo ============================================
pause
