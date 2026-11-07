#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 path/to/terraform.tfvars" >&2
  exit 64
fi

var_file=$1
if [[ ! -f "$var_file" ]]; then
  echo "Variable file not found: $var_file" >&2
  exit 66
fi

command -v terraform >/dev/null || { echo "terraform is required" >&2; exit 69; }
command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 69; }

terraform init -backend=false -input=false >/dev/null

payload=$(terraform console -no-color -var-file="$var_file" <<'EOF'
jsonencode({vpc_cidr=var.vpc_cidr,private_subnets_json=jsonencode(var.private_subnet_cidrs),remote_cidrs_json=jsonencode([var.vpc_a_cidr,var.vpc_b_cidr,var.vpc_d_cidr]),availability_zones=jsonencode(var.availability_zones)})
EOF
)

result=$(printf '%s' "$payload" | python3 scripts/cidr_validate.py --terraform-console)
printf '%s\n' "$result" | python3 -c 'import json, sys; r=json.load(sys.stdin); print(r["diagnostics"]); raise SystemExit(0 if r["valid"] == "true" else 1)'

echo "Preflight passed. This check made no AWS API calls and did not create resources."
