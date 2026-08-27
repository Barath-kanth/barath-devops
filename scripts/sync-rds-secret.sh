#!/usr/bin/env bash
# Sync RDS credentials from AWS Secrets Manager (+ endpoint from Terraform) → K8s Secret bookshelf-db.
# RDS-managed secrets often only contain username/password; host/port/dbname come from TF outputs.
# Usage:
#   AWS_PROFILE=ohohub-project ./scripts/sync-rds-secret.sh [dev]
set -euo pipefail

ENV_NAME="${1:-dev}"
AWS_REGION="${AWS_REGION:-us-east-1}"
NS="${BOOKSHELF_NS:-bookshelf}"
SECRET_NAME="${K8S_SECRET_NAME:-bookshelf-db}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DB_NAME="${DB_NAME:-appdb}"

need() { command -v "$1" >/dev/null || { echo "missing $1"; exit 1; }; }
need aws
need jq
need kubectl

cd "$ROOT/terraform/live/${ENV_NAME}"

ARN="$(terragrunt output -raw rds_master_user_secret_arn 2>/dev/null || true)"
ENDPOINT="$(terragrunt output -raw rds_endpoint 2>/dev/null || true)"
[[ -n "$ARN" && "$ARN" != "null" ]] || { echo "Missing rds_master_user_secret_arn — run terragrunt apply first"; exit 1; }
[[ -n "$ENDPOINT" && "$ENDPOINT" != "null" ]] || { echo "Missing rds_endpoint"; exit 1; }

HOST="${ENDPOINT%%:*}"
PORT="${ENDPOINT##*:}"
[[ "$PORT" == "$HOST" ]] && PORT=5432

RAW="$(aws secretsmanager get-secret-value --secret-id "$ARN" --region "$AWS_REGION" --query SecretString --output text)"
USER="$(jq -r '.username' <<<"$RAW")"
PASS="$(jq -r '.password' <<<"$RAW")"
# Prefer SM fields when present (some secret shapes include host/dbname)
HOST="$(jq -r --arg h "$HOST" '.host // .hostname // $h' <<<"$RAW")"
PORT="$(jq -r --arg p "$PORT" '.port // $p' <<<"$RAW")"
DB="$(jq -r --arg d "$DB_NAME" '.dbname // .database // $d' <<<"$RAW")"
HOST="${HOST%%:*}"

kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -
kubectl -n "$NS" create secret generic "$SECRET_NAME" \
  --from-literal=host="$HOST" \
  --from-literal=port="$PORT" \
  --from-literal=username="$USER" \
  --from-literal=password="$PASS" \
  --from-literal=dbname="$DB" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Synced $SECRET_NAME in ns/$NS (host=$HOST port=$PORT db=$DB user=$USER)"
