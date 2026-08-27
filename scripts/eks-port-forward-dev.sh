#!/usr/bin/env bash
# Port-forward to the EKS API server via SSM bastion (no public API / no SSH).
# Pattern matches the staging example (AWS-StartPortForwardingSessionToRemoteHost).
#
# Usage:
#   ./scripts/eks-port-forward-dev.sh [local_port]
# Example:
#   ./scripts/eks-port-forward-dev.sh 8443
#
# Keep this terminal open. In another terminal, point kubectl at localhost.

set -euo pipefail

ENVIRONMENT="${ENVIRONMENT:-dev}"
REGION="${AWS_REGION:-us-east-1}"
PROFILE="${AWS_PROFILE:-ohohub-project}"
CLUSTER_NAME="${CLUSTER_NAME:-aws-devops-${ENVIRONMENT}}"
BASTION_NAME_TAG="${BASTION_NAME_TAG:-aws-devops-${ENVIRONMENT}-bastion}"
LOCAL_PORT="${1:-8443}"

echo "Setting up EKS API port-forward (${ENVIRONMENT}) on localhost:${LOCAL_PORT}..."

export AWS_PROFILE="$PROFILE"
export AWS_REGION="$REGION"
export AWS_DEFAULT_REGION="$REGION"

echo "Resolving bastion instance (${BASTION_NAME_TAG})..."
BASTION_ID=$(aws ec2 describe-instances \
  --region "$REGION" \
  --filters \
    "Name=tag:Name,Values=${BASTION_NAME_TAG}" \
    "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text)

if [[ -z "$BASTION_ID" || "$BASTION_ID" == "None" ]]; then
  echo "Error: bastion not found/running. Apply terraform with enable_bastion=true first."
  exit 1
fi
echo "Bastion Instance ID: $BASTION_ID"

echo "Resolving EKS API endpoint (${CLUSTER_NAME})..."
CLUSTER_ENDPOINT=$(aws eks describe-cluster \
  --region "$REGION" \
  --name "$CLUSTER_NAME" \
  --query "cluster.endpoint" \
  --output text)

if [[ -z "$CLUSTER_ENDPOINT" || "$CLUSTER_ENDPOINT" == "None" ]]; then
  echo "Error: could not read EKS endpoint."
  exit 1
fi

ENDPOINT_HOST="${CLUSTER_ENDPOINT#https://}"
echo "EKS API Endpoint: $ENDPOINT_HOST"

ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
CONTEXT_USER="arn:aws:eks:${REGION}:${ACCOUNT}:cluster/${CLUSTER_NAME}"

cat <<EOF

========================================================================
Leave THIS terminal open (SSM port-forward).

In ANOTHER terminal:

  export AWS_PROFILE=${PROFILE}
  export AWS_REGION=${REGION}

  # Point kubectl at the tunnel (TLS verify skipped for localhost forward)
  kubectl config set-cluster ${CLUSTER_NAME}-local \\
    --server=https://localhost:${LOCAL_PORT} \\
    --insecure-skip-tls-verify=true

  # Re-use IAM auth from the real cluster context (after one update-kubeconfig)
  aws eks update-kubeconfig --region ${REGION} --name ${CLUSTER_NAME}
  kubectl config set-context ${CLUSTER_NAME}-local \\
    --cluster=${CLUSTER_NAME}-local \\
    --user=$(kubectl config view -o jsonpath="{.contexts[?(@.name=='arn:aws:eks:${REGION}:${ACCOUNT}:cluster/${CLUSTER_NAME}')].context.user}")
  kubectl config use-context ${CLUSTER_NAME}-local

  kubectl get nodes
========================================================================

Starting SSM port-forward (Ctrl+C to stop)...

EOF

aws ssm start-session \
  --region "$REGION" \
  --target "$BASTION_ID" \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters "{\"host\":[\"${ENDPOINT_HOST}\"],\"portNumber\":[\"443\"],\"localPortNumber\":[\"${LOCAL_PORT}\"]}"
