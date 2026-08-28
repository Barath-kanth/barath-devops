# Bookshelf Platform — Architecture

## Diagram

```mermaid
flowchart TB
  subgraph Internet
    Users[Users]
    GHA[GitHub Actions CI]
  end

  subgraph Edge
    CF[CloudFront]
    S3Static[S3 landing]
    NLB[NLB]
  end

  subgraph VPC
    subgraph Public
      NAT[NAT Gateway]
    end

    subgraph Private
      EKS[EKS]
      Apps[Bookshelf pods]
      Obs[Prometheus Grafana Loki OTel]
      TrivyOp[Trivy Operator]
      Falco[Falco]
      Kyverno[Kyverno]
      ESO[External Secrets]
      Argo[Argo CD]
    end

    subgraph Data
      RDS[(RDS Postgres)]
      SM[Secrets Manager]
    end
  end

  Users --> CF
  CF --> S3Static
  Users --> NLB
  NLB --> Apps
  Apps --> RDS
  RDS --> SM
  ESO --> SM
  ESO -.-> Apps

  GHA -->|build push| ECR[(ECR)]
  GHA -->|Trivy image scan| GHA
  ECR --> Apps
  Argo --> Apps
  TrivyOp --> Apps
  Falco -->|runtime events| Apps
  Kyverno --> Apps
  Obs --> Apps
  Falco --> Obs
  Apps --> NAT
```

## Security

| Layer | Tool | Where |
|-------|------|-------|
| Image scan (CI) | Trivy | GitHub Actions — before ECR push |
| Image/config scan (cluster) | Trivy Operator | `trivy-system` |
| Runtime threats | Falco | `falco` namespace |
| Admission policy | Kyverno | `kyverno` |

## Components

| Area | Implementation |
|------|----------------|
| Infra | Terraform/Terragrunt — `terraform/live/{dev,stage,prod}` |
| Apps | Helm chart + Argo CD GitOps |
| Ingress | Istio Gateway + NLB |
| Landing | S3 + CloudFront |
| Secrets | SM → ESO → K8s `bookshelf-db` |
| Governance | Kyverno + Trivy + Falco + NetworkPolicies |
| CI/CD | GHA → Trivy scan → ECR → `image-tags.yaml` → Argo sync |
