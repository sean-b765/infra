# Terraform Infra

## Deploying anew

1. Comment out `backend "s3"` block in `terraform.tf`
2. Run `terraform init`
2. Run `terraform apply` to create the S3 bucket / DynamoDB table which stores tfstate
3. Uncomment `backend "s3"` block in `terraform.tf`
4. Run `terraform init -migrate-state`