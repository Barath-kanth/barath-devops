#!/usr/bin/env bash
# One-time cluster bootstrap (Helm installs). Ongoing config is Argo CD.
# AWS_PROFILE=ohohub-project ENV_NAME=dev ./k8s/gitops/bootstrap.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export AWS_REGION="${AWS_REGION:-us-east-1}"

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace trivy-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace opentelemetry-operator-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace falco --dry-run=client -o yaml | kubectl apply -f -

helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo add aqua https://aquasecurity.github.io/helm-charts 2>/dev/null || true
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts 2>/dev/null || true
helm repo add jetstack https://charts.jetstack.io 2>/dev/null || true
helm repo add falcosecurity https://falcosecurity.github.io/charts 2>/dev/null || true
helm repo update

echo "cert-manager"
helm upgrade --install cert-manager jetstack/cert-manager -n cert-manager \
  --version v1.17.2 \
  --set crds.enabled=true \
  --set resources.requests.cpu=20m \
  --set resources.requests.memory=64Mi \
  --wait --timeout 5m

echo "argocd"
helm upgrade --install argocd argo/argo-cd -n argocd \
  --version 7.8.28 \
  -f "$ROOT/k8s/gitops/argocd/values.yaml" \
  --wait --timeout 8m

echo "prometheus stack"
helm upgrade --install kps prometheus-community/kube-prometheus-stack -n observability \
  --version 70.4.1 \
  -f "$ROOT/k8s/gitops/observability/prometheus/values.yaml" \
  --wait --timeout 10m

echo "loki"
helm upgrade --install loki grafana/loki -n observability \
  --version 6.27.0 \
  -f "$ROOT/k8s/gitops/observability/loki/values.yaml" \
  --wait --timeout 8m

echo "alloy"
helm upgrade --install alloy grafana/alloy -n observability \
  --version 0.12.5 \
  -f "$ROOT/k8s/gitops/observability/loki/alloy-values.yaml" \
  --wait --timeout 5m

echo "trivy-operator"
helm upgrade --install trivy-operator aqua/trivy-operator -n trivy-system \
  --version 0.28.0 \
  -f "$ROOT/k8s/gitops/observability/trivy/values.yaml" \
  --wait --timeout 5m

echo "otel operator"
helm upgrade --install opentelemetry-operator open-telemetry/opentelemetry-operator \
  -n opentelemetry-operator-system \
  --version 0.86.2 \
  -f "$ROOT/k8s/gitops/observability/otel/operator-values.yaml" \
  --wait --timeout 5m

for i in $(seq 1 30); do
  kubectl get crd opentelemetrycollectors.opentelemetry.io >/dev/null 2>&1 && break
  sleep 2
done
kubectl apply -f "$ROOT/k8s/gitops/observability/otel/collector-instrumentation.yaml"

echo "kyverno"
kubectl create namespace kyverno --dry-run=client -o yaml | kubectl apply -f -
helm repo add kyverno https://kyverno.github.io/kyverno/ 2>/dev/null || true
helm repo update kyverno
helm upgrade --install kyverno kyverno/kyverno -n kyverno \
  --version 3.8.2 \
  --set admissionController.replicas=1 \
  --set backgroundController.resources.requests.memory=64Mi \
  --set reportsController.resources.requests.memory=64Mi \
  --wait --timeout 8m || echo "kyverno install failed — retry later"

# Remove legacy ClusterPolicy resources if upgrading from kyverno.io/v1 policies
kubectl delete clusterpolicy require-requests-limits disallow-privileged require-app-label disallow-latest-tag \
  --ignore-not-found || true

kubectl apply -f "$ROOT/k8s/gitops/policy/policies.yaml" || true

echo "falco"
helm upgrade --install falco falcosecurity/falco -n falco \
  --version 4.11.1 \
  -f "$ROOT/k8s/gitops/governance/falco/values.yaml" \
  --wait --timeout 8m || echo "falco install failed — retry later"

echo "external-secrets"
kubectl create namespace external-secrets --dry-run=client -o yaml | kubectl apply -f -
helm repo add external-secrets https://charts.external-secrets.io 2>/dev/null || true
helm repo update external-secrets
helm upgrade --install external-secrets external-secrets/external-secrets -n external-secrets \
  --version 0.14.3 \
  -f "$ROOT/k8s/gitops/secrets/external-secrets-values.yaml" \
  --wait --timeout 5m

ROLE=$(cd "$ROOT/terraform/live/${ENV_NAME:-dev}" && terragrunt output -raw external_secrets_role_arn)
kubectl annotate serviceaccount external-secrets -n external-secrets \
  eks.amazonaws.com/role-arn="$ROLE" --overwrite

kubectl label ns bookshelf istio-injection=disabled --overwrite
for dep in catalog-api loans-api; do
  kubectl annotate deployment/"$dep" -n bookshelf \
    instrumentation.opentelemetry.io/inject-nodejs="observability/bookshelf-nodejs" \
    --overwrite
done
kubectl rollout restart deployment/catalog-api deployment/loans-api -n bookshelf || true

echo "argocd apps"
kubectl apply -f "$ROOT/k8s/gitops/argocd/bookshelf-application.yaml"
kubectl apply -f "$ROOT/k8s/gitops/argocd/observability-applications.yaml"
kubectl apply -f "$ROOT/k8s/gitops/argocd/governance-applications.yaml"
kubectl apply -f "$ROOT/k8s/gitops/argocd/root-application.yaml"

echo "done."
