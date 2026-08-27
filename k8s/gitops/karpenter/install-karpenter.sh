#!/usr/bin/env bash
# Install Karpenter controller (IRSA + Helm + NodePool) for aws-devops-dev
set -euo pipefail
export AWS_REGION="${AWS_REGION:-us-east-1}"
export AWS_PROFILE="${AWS_PROFILE:-ohohub-project}"
CLUSTER=aws-devops-dev
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
OIDC_ISSUER=$(aws eks describe-cluster --name "$CLUSTER" --query cluster.identity.oidc.issuer --output text)
OIDC_HOSTPATH="${OIDC_ISSUER#https://}"
ENDPOINT=$(aws eks describe-cluster --name "$CLUSTER" --query cluster.endpoint --output text)
NODE_SG=$(aws eks describe-cluster --name "$CLUSTER" --query 'cluster.resourcesVpcConfig.clusterSecurityGroupId' --output text)

# Tag cluster SG for Karpenter discovery (private subnets already tagged)
aws ec2 create-tags --resources "$NODE_SG" --tags Key=karpenter.sh/discovery,Value="$CLUSTER" 2>/dev/null || \
  aws ec2 create-tags --resources "$(aws eks describe-nodegroup --cluster-name $CLUSTER --nodegroup-name $(aws eks list-nodegroups --cluster-name $CLUSTER --query nodegroups[0] --output text) --query 'nodegroup.resources.remoteAccessSecurityGroup' --output text 2>/dev/null || true)" --tags Key=karpenter.sh/discovery,Value=$CLUSTER 2>/dev/null || true

# Prefer tagging the node security group used by managed nodes
NG=$(aws eks list-nodegroups --cluster-name "$CLUSTER" --query 'nodegroups[0]' --output text)
# Get node SG from an instance
INST=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
NODE_INSTANCE_SG=$(aws ec2 describe-instances --filters "Name=private-ip-address,Values=$INST" --query 'Reservations[0].Instances[0].SecurityGroups[?contains(GroupName, `node`) || contains(GroupName, `Node`)].GroupId' --output text | awk '{print $1}')
if [ -z "$NODE_INSTANCE_SG" ] || [ "$NODE_INSTANCE_SG" = "None" ]; then
  NODE_INSTANCE_SG=$(aws ec2 describe-instances --filters "Name=private-ip-address,Values=$INST" --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text)
fi
echo "Tagging node SG $NODE_INSTANCE_SG for karpenter discovery"
aws ec2 create-tags --resources "$NODE_INSTANCE_SG" --tags Key=karpenter.sh/discovery,Value="$CLUSTER"

# --- Node role ---
NODE_ROLE=KarpenterNodeRole-$CLUSTER
if ! aws iam get-role --role-name "$NODE_ROLE" >/dev/null 2>&1; then
  cat >/tmp/karpenter-node-trust.json <<EOF
{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}
EOF
  aws iam create-role --role-name "$NODE_ROLE" --assume-role-policy-document file:///tmp/karpenter-node-trust.json
  for p in AmazonEKSWorkerNodePolicy AmazonEKS_CNI_Policy AmazonEC2ContainerRegistryReadOnly AmazonSSMManagedInstanceCore; do
    aws iam attach-role-policy --role-name "$NODE_ROLE" --policy-arn arn:aws:iam::aws:policy/$p
  done
  aws iam create-instance-profile --instance-profile-name "$NODE_ROLE" 2>/dev/null || true
  aws iam add-role-to-instance-profile --instance-profile-name "$NODE_ROLE" --role-name "$NODE_ROLE" 2>/dev/null || true
fi

# --- Controller role (IRSA) ---
CTRL_ROLE=KarpenterControllerRole-$CLUSTER
OIDC_PROVIDER_ARN=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?contains(Arn, '${OIDC_HOSTPATH##*/}')].Arn" --output text)
if [ -z "$OIDC_PROVIDER_ARN" ] || [ "$OIDC_PROVIDER_ARN" = "None" ]; then
  OIDC_PROVIDER_ARN="arn:aws:iam::${ACCOUNT}:oidc-provider/${OIDC_HOSTPATH}"
fi

cat >/tmp/karpenter-ctrl-trust.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Federated": "${OIDC_PROVIDER_ARN}"},
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "${OIDC_HOSTPATH}:aud": "sts.amazonaws.com",
        "${OIDC_HOSTPATH}:sub": "system:serviceaccount:kube-system:karpenter"
      }
    }
  }]
}
EOF

if ! aws iam get-role --role-name "$CTRL_ROLE" >/dev/null 2>&1; then
  aws iam create-role --role-name "$CTRL_ROLE" --assume-role-policy-document file:///tmp/karpenter-ctrl-trust.json
else
  aws iam update-assume-role-policy --role-name "$CTRL_ROLE" --policy-document file:///tmp/karpenter-ctrl-trust.json
fi

# Controller policy (scoped)
cat >/tmp/karpenter-ctrl-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Karpenter",
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ec2:DescribeImages",
        "ec2:RunInstances",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeLaunchTemplates",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeInstanceTypeOfferings",
        "ec2:DescribeAvailabilityZones",
        "ec2:DeleteLaunchTemplate",
        "ec2:CreateTags",
        "ec2:CreateLaunchTemplate",
        "ec2:CreateFleet",
        "ec2:DescribeSpotPriceHistory",
        "pricing:GetProducts"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ConditionalEC2Termination",
      "Effect": "Allow",
      "Action": "ec2:TerminateInstances",
      "Resource": "*",
      "Condition": {"StringLike": {"ec2:ResourceTag/karpenter.sh/nodepool": "*"}}
    },
    {
      "Sid": "PassNodeIAMRole",
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "arn:aws:iam::${ACCOUNT}:role/${NODE_ROLE}"
    },
    {
      "Sid": "EKSClusterEndpointLookup",
      "Effect": "Allow",
      "Action": "eks:DescribeCluster",
      "Resource": "arn:aws:eks:${AWS_REGION}:${ACCOUNT}:cluster/${CLUSTER}"
    },
    {
      "Sid": "InstanceProfile",
      "Effect": "Allow",
      "Action": [
        "iam:GetInstanceProfile",
        "iam:CreateInstanceProfile",
        "iam:TagInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:DeleteInstanceProfile"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SQS",
      "Effect": "Allow",
      "Action": [
        "sqs:DeleteMessage",
        "sqs:GetQueueUrl",
        "sqs:ReceiveMessage"
      ],
      "Resource": "arn:aws:sqs:${AWS_REGION}:${ACCOUNT}:Karpenter-${CLUSTER}"
    }
  ]
}
EOF
aws iam put-role-policy --role-name "$CTRL_ROLE" --policy-name KarpenterControllerPolicy --policy-document file:///tmp/karpenter-ctrl-policy.json

# Interruption queue
QUEUE=Karpenter-$CLUSTER
aws sqs create-queue --queue-name "$QUEUE" --attributes '{"MessageRetentionPeriod":"300"}' 2>/dev/null || true

# Access entry so Karpenter nodes can join
aws eks create-access-entry --cluster-name "$CLUSTER" --principal-arn "arn:aws:iam::${ACCOUNT}:role/${NODE_ROLE}" --type EC2_LINUX 2>/dev/null || true
aws eks associate-access-policy --cluster-name "$CLUSTER" --principal-arn "arn:aws:iam::${ACCOUNT}:role/${NODE_ROLE}" \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSNodePolicy --access-scope type=cluster 2>/dev/null || true

# SA + Helm
kubectl create namespace kube-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create serviceaccount karpenter -n kube-system --dry-run=client -o yaml | kubectl apply -f -
kubectl annotate serviceaccount karpenter -n kube-system \
  eks.amazonaws.com/role-arn="arn:aws:iam::${ACCOUNT}:role/${CTRL_ROLE}" --overwrite

KARPENTER_VERSION=1.3.3
helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter \
  --version "$KARPENTER_VERSION" \
  --namespace kube-system \
  --set settings.clusterName="$CLUSTER" \
  --set settings.clusterEndpoint="$ENDPOINT" \
  --set settings.interruptionQueue="$QUEUE" \
  --set serviceAccount.create=false \
  --set serviceAccount.name=karpenter \
  --set controller.resources.requests.cpu=100m \
  --set controller.resources.requests.memory=256Mi \
  --wait --timeout 5m

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
kubectl apply -f "$ROOT/k8s/gitops/karpenter/nodepool.yaml"
kubectl get pods -n kube-system -l app.kubernetes.io/name=karpenter
kubectl get nodepool,ec2nodeclass
echo "Karpenter installed."
