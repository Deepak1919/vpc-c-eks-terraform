#!/usr/bin/env bash
set -euo pipefail

command -v terraform >/dev/null || { echo "terraform is required" >&2; exit 69; }

terraform fmt -check -recursive
terraform init -backend=false -input=false
terraform validate

command -v kubectl >/dev/null || { echo "kubectl is required to validate Kubernetes examples" >&2; exit 69; }
kubectl kustomize kubernetes/api-deployment-1 >/dev/null
kubectl kustomize kubernetes/api-deployment-2 >/dev/null

if command -v tflint >/dev/null; then
  tflint --recursive
else
  echo "INFO: tflint is not installed; skipped."
fi

if command -v checkov >/dev/null; then
  checkov -d . --quiet
else
  echo "INFO: checkov is not installed; skipped."
fi

echo "Static validation completed. No terraform plan or apply was run."
