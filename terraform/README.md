# Terraform + Terragrunt layout

```
terraform/
  modules/
    network | eks | rds | s3 | cloudfront
    platform/                 # composition (wires the modules above)
  live/
    root.hcl                  # S3 remote_state (use_lockfile) + versions
    dev/terragrunt.hcl        # → aws-devops-assessment/dev/terraform.tfstate
    stage/terragrunt.hcl
    prod/terragrunt.hcl
```

## Backend (no DynamoDB)

Terragrunt generates `backend.tf` from `live/root.hcl`:

```hcl
terraform {
  backend "s3" {
    bucket       = "barath-devops-tfstate-927120871634"
    key          = "aws-devops-assessment/<env>/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true   # S3-native lock (.tflock) — replaces DynamoDB
  }
}
```

Requires **Terraform >= 1.11**.

### Create the state bucket once

```bash
export AWS_PROFILE=ohohub-project AWS_REGION=us-east-1
BUCKET=barath-devops-tfstate-927120871634

aws s3api create-bucket --bucket "$BUCKET" --region us-east-1
aws s3api put-bucket-versioning --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket "$BUCKET" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
aws s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

## Apply an environment

```bash
brew install terragrunt   # if needed
cd terraform/live/dev
terragrunt init
terragrunt plan
terragrunt apply
```

State keys:

```text
aws-devops-assessment/dev/terraform.tfstate
aws-devops-assessment/stage/terraform.tfstate
aws-devops-assessment/prod/terraform.tfstate
```
