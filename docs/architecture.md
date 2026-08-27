# Bookshelf Platform — Architecture

Assessment: Surge Global DevOps Technical Assessment (cloud-agnostic patterns on **AWS**).

## High-level diagram

```mermaid
flowchart TB
  subgraph Internet
    Users[Users / CI]
    Attacker[Geo / DDoS threats]
  end

  subgraph Edge["Edge & CDN"]
    CF[CloudFront + WAF* / Geo restriction*]
    S3Static[S3 static landing]
    NLB[Internet-facing NLB]
  end

  subgraph VPC["VPC multi-AZ"]
    subgraph Public["Public subnets"]
      NAT[NAT Gateway]
    end

    subgraph Private["Private subnets"]
      Bastion[SSM Bastion t3.micro]
      EKS[EKS control plane ENIs]
      Nodes[Managed nodes + Karpenter]
      Istio[Istio Ingress Gateway]
      Apps[Bookshelf pods + sidecars]
      Obs[Prometheus Grafana Loki Alloy OTel Trivy]
      Argo[Argo CD]
    end

    subgraph Data["Database subnets"]
      RDS[(RDS PostgreSQL)]
      SM[Secrets Manager]
    end

    VPCE[SSM VPC Endpoints]
  end

  Users -->|HTTPS| CF
  CF --> S3Static
  Users -->|HTTP app| NLB
  NLB --> Istio
  Istio -->|mTLS| Apps
  Apps --> RDS
  RDS --> SM
  Users -.->|break-glass only| EKS
  Bastion -->|SSM port-forward 443| EKS
  Users -->|SSM Session| Bastion
  Bastion --> VPCE
  Nodes --> NAT
  Apps --> Obs
  Argo --> Apps

  Attacker -.->|blocked / rate-limited*| CF
```

\*WAF / multi-region DR shown as design options (diagram bonus); not all are required to be live.

## Component map (assessment checklist)

| Requirement | Implementation |
|-------------|----------------|
| Multi-env Terraform | `terraform/live/{dev,stage,prod}` + Terragrunt `root.hcl` remote state |
| K8s best practices | EKS 1.34, private nodes, IRSA/OIDC, node SG, Karpenter |
| Networking | VPC, public/private/db subnets, NAT, flow logs |
| Secrets | RDS master secret in **Secrets Manager**; no passwords in Git |
| Storage + DB | EBS (CSI), S3; RDS Postgres in isolated subnets |
| Helm deploy | Umbrella chart `k8s/helm/chart/bookshelf` |
| Resilience / HPA / PDB | Deployments, HPA, PDBs, Istio retries/outlier |
| Gateway + LB | Istio Gateway + AWS NLB |
| Static + cache | S3 + CloudFront OAC |
| CI/CD | GitHub Actions → ECR → GitOps tag bump |
| Argo CD (bonus) | GitOps Applications under `k8s/gitops/argocd` |
| Observability (bonus) | Prometheus, Grafana, Loki, Alloy, OTel auto-instr, Kiali |
| Governance (bonus) | Trivy Operator, NetworkPolicies (chart), mesh AuthZ, STRICT mTLS |
| Private API access | Bastion + SSM port-forward (`scripts/eks-port-forward-*.sh`) |

## EKS API access model

1. **Private endpoint**: always on (`endpoint_private_access = true`).
2. **Public endpoint**: **off** in hardened env (`eks_endpoint_public_access = false`).
3. Operators run `scripts/eks-port-forward-dev.sh` → SSM → bastion → API `:443` on `localhost:8443`.
4. kubectl uses `https://localhost:8443` with IAM auth from `aws eks get-token`.

## Security / DR notes (diagram extras)

- CloudFront geo / WAF / Shield for country-level attack reduction.
- Multi-AZ nodes + RDS Multi-AZ (prod) for AZ failure.
- Cross-region S3 replication + secondary CloudFront origin for DR (design only).
- GitOps + immutable ECR tags for rollback.
