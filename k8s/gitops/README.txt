Order after EKS exists:

1. terragrunt apply in terraform/live/dev
2. eks-port-forward-dev.sh + kubeconfig
3. bootstrap.sh
4. karpenter/install-karpenter.sh
5. mesh/policies.yaml

Argo CD apps are registered at the end of bootstrap.sh.
Image tags in k8s/helm/chart/bookshelf/image-tags.yaml are bumped by CI.
