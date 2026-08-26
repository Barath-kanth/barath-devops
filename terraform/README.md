# Terraform + Terragrunt layout

```
terraform/
  modules/
    network | eks | rds | s3 | cloudfront
    platform/                 # composition (wires the modules above)
  live/
    root.hcl                  # shared remote_state + versions
    dev/terragrunt.hcl        # inputs for dev  → own state key
    stage/terragrunt.hcl
    prod/terragrunt.hcl
```

## Why Terragrunt here

- **Separate state per env** via `remote_state` key = `.../${path_relative_to_include()}/terraform.tfstate`
- **No duplicated** `main.tf` / `variables.tf` / `backend.tf` across envs
- **Blast radius**: a bad apply in `live/dev` cannot touch prod state/resources

## Prerequisites

```bash
brew install terragrunt   # or https://terragrunt.gruntwork.io/docs/getting-started/install/
```

## Apply an environment

```bash
cd terraform/live/dev
terragrunt init
terragrunt plan
terragrunt apply
```

When the S3 state bucket + DynamoDB lock table exist, uncomment `remote_state` in
`live/root.hcl` and set `bucket` / `dynamodb_table`.

State keys will look like:

```text
aws-devops-assessment/dev/terraform.tfstate
aws-devops-assessment/stage/terraform.tfstate
aws-devops-assessment/prod/terraform.tfstate
```
