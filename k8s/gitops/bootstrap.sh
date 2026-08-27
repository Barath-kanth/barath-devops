#!/usr/bin/env bash
# Bootstrap platform add-ons (Argo CD + observability). Values live under k8s/gitops/.
# Usage: AWS_PROFILE=ohohub-project ./k8s/gitops/bootstrap.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export AWS_REGION="${AWS_REGION:-us-east-1}"

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace trivy-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace opentelemetry-operator-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -

helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo add aqua https://aquasecurity.github.io/helm-charts 2>/dev/null || true
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts 2>/dev/null || true
helm repo add jetstack https://charts.jetstack.io 2>/dev/null || true
helm repo update

echo "==> cert-manager (required by OTel Operator webhooks)"
helm upgrade --install cert-manager jetstack/cert-manager -n cert-manager \
  --version v1.17.2 \
  --set crds.enabled=true \
  --set resources.requests.cpu=20m \
  --set resources.requests.memory=64Mi \
  --wait --timeout 5m

echo "==> Argo CD"
helm upgrade --install argocd argo/argo-cd -n argocd \
  --version 7.8.28 \
  -f "$ROOT/k8s/gitops/argocd/values.yaml" \
  --wait --timeout 8m

echo "==> kube-prometheus-stack (Prometheus + Grafana + Alertmanager)"
helm upgrade --install kps prometheus-community/kube-prometheus-stack -n observability \
  --version 70.4.1 \
  -f "$ROOT/k8s/gitops/observability/prometheus/values.yaml" \
  --wait --timeout 10m

echo "==> Loki"
helm upgrade --install loki grafana/loki -n observability \
  --version 6.27.0 \
  -f "$ROOT/k8s/gitops/observability/loki/values.yaml" \
  --wait --timeout 8m

echo "==> Grafana Alloy (logs → Loki)"
helm upgrade --install alloy grafana/alloy -n observability \
  --version 0.12.5 \
  -f "$ROOT/k8s/gitops/observability/loki/alloy-values.yaml" \
  --wait --timeout 5m

echo "==> Trivy Operator"
helm upgrade --install trivy-operator aqua/trivy-operator -n trivy-system \
  --version 0.28.0 \
  -f "$ROOT/k8s/gitops/observability/trivy/values.yaml" \
  --wait --timeout 5m

echo "==> OpenTelemetry Operator"
helm upgrade --install opentelemetry-operator open-telemetry/opentelemetry-operator \
  -n opentelemetry-operator-system \
  --version 0.86.2 \
  -f "$ROOT/k8s/gitops/observability/otel/operator-values.yaml" \
  --wait --timeout 5m

echo "==> OTel Collector + Instrumentation CRs"
# Wait for CRDs
for i in $(seq 1 30); do
  kubectl get crd opentelemetrycollectors.opentelemetry.io >/dev/null 2>&1 && break
  sleep 2
done
kubectl apply -f "$ROOT/k8s/gitops/observability/otel/collector-instrumentation.yaml"

echo "==> Kyverno (admission policies)"
kubectl create namespace kyverno --dry-run=client -o yaml | kubectl apply -f -
helm repo add kyverno https://kyverno.github.io/kyverno/ 2>/dev/null || true
helm repo update kyverno
helm upgrade --install kyverno kyverno/kyverno -n kyverno \
  --version 3.3.7 \
  --set admissionController.replicas=1 \
  --set backgroundController.resources.requests.memory=64Mi \
  --set reportsController.resources.requests.memory=64Mi \
  --wait --timeout 8m || echo "WARN: Kyverno helm install failed (retry later)"

echo "==> External Secrets Operator (optional SM sync)"
kubectl create namespace external-secrets --dry-run=client -o yaml | kubectl apply -f -
helm repo add external-secrets https://charts.external-secrets.io 2>/dev/null || true
helm repo update external-secrets
helm upgrade --install external-secrets external-secrets/external-secrets -n external-secrets \
  --version 0.14.3 \
  --set installCRDs=true \
  --set resources.requests.memory=64Mi \
  --wait --timeout 5m || echo "WARN: ESO helm install failed (use scripts/sync-rds-secret.sh)"

echo "==> Governance policies + secret docs"
kubectl apply -f "$ROOT/k8s/gitops/policy/policies.yaml" || true
kubectl apply -f "$ROOT/k8s/gitops/secrets/externalsecret.yaml" || true

echo "==> Annotate API deployments for Node.js auto-instrumentation (not frontend/nginx)"
kubectl label ns bookshelf istio-injection=disabled --overwrite
for dep in catalog-api loans-api; do
  kubectl annotate deployment/"$dep" -n bookshelf \
    instrumentation.opentelemetry.io/inject-nodejs="observability/bookshelf-nodejs" \
    --overwrite
done
kubectl rollout restart deployment/catalog-api deployment/loans-api -n bookshelf || true

echo "==> Register Argo CD Applications (GitOps ownership going forward)"
kubectl apply -f "$ROOT/k8s/gitops/argocd/bookshelf-application.yaml"
kubectl apply -f "$ROOT/k8s/gitops/argocd/observability-applications.yaml"
kubectl apply -f "$ROOT/k8s/gitops/argocd/governance-applications.yaml"
kubectl apply -f "$ROOT/k8s/gitops/argocd/root-application.yaml"

echo
echo "Bootstrap complete."
echo "  Sync RDS secret:  ./scripts/sync-rds-secret.sh"
echo "  Argo CD:  kubectl -n argocd port-forward svc/argocd-server 8080:8080  # HTTP (insecure)"
echo "  Grafana:  kubectl -n observability port-forward svc/kps-grafana 3000:80"
echo "  Password: ChangeMe-Bookshelf!"
