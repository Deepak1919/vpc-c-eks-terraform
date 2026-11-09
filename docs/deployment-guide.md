# Deployment guide

## Bootstrap remote state

Terraform cannot create the S3 backend bucket in the same initialization that uses it. From `bootstrap/`, copy its example variables, select a globally unique bucket name, then have an authorized platform team review and apply that small bootstrap configuration. It enables bucket versioning, SSE-S3 encryption, and public-access blocking. Its state must be protected separately while bootstrapping.

Afterward copy `backend.hcl.example` at repository root. Set the bootstrap bucket name, a unique state key, `region = "us-east-1"`, `encrypt = true`, and `use_lockfile = true`. Terraform's native S3 lockfile is used; no DynamoDB locking table is configured. The bucket must already exist before `terraform init`.

Do not commit `backend.hcl`, `terraform.tfvars`, state files, plans, credentials, or application secrets. `.gitignore` covers the first three categories.

## Configuration sequence

1. Request approved, non-overlapping CIDR ranges and four account-specific AZ names from network engineering.
2. Obtain each existing VPC's ID, CIDR, private route-table IDs, owner account ID, region, and the authorization decision for return routes.
3. Fill `terraform.tfvars` from the example. Place only private management networks in `trusted_cidrs`; public CIDRs are rejected.
4. Select an `acceptance_mode` for each peer. `auto` is solely for compatible same-account/same-region peering. Use `external` for cross-account or inter-region requests and coordinate acceptance.
5. Run `./scripts/preflight-check.sh terraform.tfvars`, then initialize and run static validation.
6. In an authorized change window, generate a plan, inspect all routes/endpoints/IAM policies, and only apply after approval.

## Required AWS permissions

The deployment role needs scoped permissions for VPC/subnet/route table/security-group/VPC endpoint/VPC peering APIs; EKS cluster, node group, and launch template APIs; CloudWatch Log Groups; and IAM role/policy attachment operations. It also needs `iam:PassRole` constrained to the two roles created for this cluster. Cross-account route-table writes and peering acceptance require authorization in the remote account and are not implied by access to VPC C.

Scope policies by approved account, region, resource tags, VPC IDs, and managed role prefixes where the organization's authorization model permits it. Review managed EKS policy changes periodically.

## Infrastructure versus application delivery

Terraform provides network, IAM, EKS, nodes, and selected private AWS connectivity. It does not create container images, Kubernetes Secrets, ingress/load balancer controllers, Cluster Autoscaler, application databases, or application deployments. The manifests are separate examples and use intentionally invalid image references until the release team supplies approved values.

## Customer-managed encryption

Set `eks_secrets_kms_key_arn` only after its KMS key policy permits EKS use. Node root volumes are encrypted with the account default EBS KMS key through launch templates. For a customer-managed EBS key, add the organization-approved launch-template/key-policy extension before production use; do not improvise a key policy.
