# ASAP install order (after EKS exists)
#
# 1) Terragrunt: terraform/live/dev  → VPC + EKS
# 2) aws eks update-kubeconfig --name <cluster> --region us-east-1 --profile ohohub-project
# 3) Argo CD:
#      kubectl create namespace argocd
#      kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# 4) kubectl apply -f k8s/gitops/argocd/root-application.yaml
# 5) Later: Istio Ambient, observability, Karpenter, cert-manager, ExternalDNS
#
# Images already in ECR (CI). Argo syncs Helm when values.yaml tags change.
