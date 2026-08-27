# aws-devops-assessment (Bookshelf)

Secure, multi-environment platform for backend APIs + SPA, mapped to the Surge Global DevOps assessment.

## Assumptions

- **Cloud: AWS** — confirmed with the assessment team as an accepted choice (brief lists GCP/Azure; patterns remain portable via Terraform/Helm/GitOps).
- Account/profile: `ohohub-project`, region `us-east-1`, account `927120871634`.
- GitHub repo: `Barath-kanth/barath-devops` (CI + Argo source).
- Cost-sensitive: scale down / `terragrunt destroy` in `terraform/live/dev` when idle.

## Quick map to the brief

| # | Requirement | Where |
|---|-------------|--------|
| 1 | Multi-env Terraform + remote state | `terraform/live/{dev,stage,prod}`, `root.hcl` (S3 + `use_lockfile`) |
| 1 | EKS, VPC, secrets, storage, DB | `terraform/modules/{network,eks,bastion,rds,s3,cloudfront,platform}` |
| 2 | Helm apps + Gateway + LB | `k8s/helm/chart/bookshelf`, Istio Gateway + NLB |
| 3 | Static landing + cache | S3 + CloudFront; CI job `landing` syncs `apps/landing/` |
| 4 | CI/CD + Argo CD | `.github/workflows/ci-cd-gitops.yml`, `k8s/gitops/argocd/` |
| 5 | Governance + observability | Kyverno policies, Trivy, Prometheus/Grafana/Loki/OTel/Kiali |
| 7 | Architecture diagram (PDF) | [`docs/architecture.pdf`](docs/architecture.pdf) |

## Secrets + RDS

- RDS Postgres master password lives in **AWS Secrets Manager** (`manage_master_user_password`).
- Apps read `PGHOST` / `PGUSER` / `PGPASSWORD` / `PGDATABASE` (fallback: in-memory if unset).
- Sync into the cluster:

```bash
./scripts/sync-rds-secret.sh          # → Secret bookshelf/bookshelf-db
# optional continuous sync: External Secrets Operator + IRSA (output external_secrets_role_arn)
```

## Private EKS API + bastion (SSM)

- **Private** API endpoint: enabled  
- **Public** API endpoint: **disabled**  
- **Bastion** in a private subnet (SSM only) + VPC endpoints for SSM  

### Apply (dev)

```bash
export AWS_PROFILE=ohohub-project AWS_REGION=us-east-1
cd terraform/live/dev && terragrunt apply
```

### kubectl via port-forward

```bash
./scripts/eks-port-forward-dev.sh 8443
# then use context aws-devops-dev-local (see script output / docs)
```

## Platform bootstrap

```bash
./k8s/gitops/bootstrap.sh
./scripts/sync-rds-secret.sh
./k8s/gitops/karpenter/install-karpenter.sh
kubectl apply -f k8s/gitops/mesh/policies.yaml
```

## CI repo variables

| Variable | Purpose |
|----------|---------|
| `AWS_ROLE_TO_ASSUME` | OIDC role for ECR + S3/CloudFront |
| `ECR_REGISTRY` | e.g. `927120871634.dkr.ecr.us-east-1.amazonaws.com` |
| `STATIC_BUCKET_NAME` | Landing bucket (default: `aws-devops-dev-static-927120871634`) |
| `CLOUDFRONT_DISTRIBUTION_ID` | Optional; enables cache invalidation |

## Useful ports

- Landing: CloudFront domain (`terragrunt output cloudfront_domain_name`)  
- Grafana: `kubectl -n observability port-forward svc/kps-grafana 3000:80`  
- Kiali: `kubectl -n istio-system port-forward svc/kiali 20001:20001`  
- Argo CD: `kubectl -n argocd port-forward deploy/argocd-server 8080:8080` (HTTP)

## Destroy

```bash
cd terraform/live/dev && terragrunt destroy
```
