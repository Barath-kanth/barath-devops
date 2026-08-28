# Bookshelf — DevOps assessment

Backend APIs + SPA on EKS. Static landing on S3/CloudFront. Terraform for infra, Helm + Argo CD for apps.

## Assumptions

- AWS (`us-east-1`), account `927120871634`, profile `ohohub-project`
- Repo: `Barath-kanth/barath-devops`
- Team approved AWS instead of GCP/Azure for this submission
- Only **dev** is wired end-to-end; stage/prod use the same Terragrunt layout

## Where things live

| Area | Path |
|------|------|
| Terraform (dev/stage/prod) | `terraform/live/` |
| Helm chart | `k8s/helm/chart/bookshelf` |
| Argo CD apps | `k8s/gitops/argocd/` |
| CI | `.github/workflows/ci-cd-gitops.yml` |
| Architecture PDF | `docs/architecture.pdf` |

## RDS + secrets

RDS password is in Secrets Manager (`manage_master_user_password`). Terraform also writes `aws-devops-<env>/bookshelf-db` for the app connection string. External Secrets Operator syncs that into `bookshelf/bookshelf-db`; pods read it via `envFrom`.

```bash
kubectl -n bookshelf get externalsecret,secret bookshelf-db
```

## Deploy flow

1. `cd terraform/live/dev && terragrunt apply`
2. `./scripts/eks-port-forward-dev.sh 8443` (private API — keep terminal open)
3. `./k8s/gitops/bootstrap.sh`
4. `./k8s/gitops/karpenter/install-karpenter.sh`
5. `kubectl apply -f k8s/gitops/mesh/policies.yaml`

Push to `main` with app changes → GitHub Actions builds images, pushes ECR, updates `image-tags.yaml`. Argo CD has automated sync on the bookshelf app so the cluster picks up the new tag without a manual sync.

Helm-only edits under `k8s/` go straight to Git; Argo syncs those on its own.

## CI variables (GitHub)

| Variable | Notes |
|----------|-------|
| `AWS_ROLE_TO_ASSUME` | OIDC role for ECR + S3 |
| `ECR_REGISTRY` | `927120871634.dkr.ecr.us-east-1.amazonaws.com` |
| `STATIC_BUCKET_NAME` | landing bucket |
| `CLOUDFRONT_DISTRIBUTION_ID` | for cache invalidation |

## Handy commands

```bash
# kubectl (after port-forward script)
kubectl -n argocd get applications
kubectl -n bookshelf get pods

# UIs
kubectl -n argocd port-forward svc/argocd-server 8080:8080
kubectl -n observability port-forward svc/kps-grafana 3000:80
```

## Teardown

```bash
cd terraform/live/dev && terragrunt destroy
```
