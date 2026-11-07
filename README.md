# VPC C EKS Terraform template

This repository provisions the new private Application/EKS VPC (VPC C), a private Amazon EKS cluster, four isolated managed node groups, private AWS service endpoints, and optional VPC C peering to the existing Bank (A), NPCI (B), and Database (D) VPCs. It is a reusable template: client-specific values live only in `terraform.tfvars` and `backend.hcl`.

It does **not** deploy Kubernetes applications, run `terraform apply`, or create anything merely by being cloned. The Kubernetes examples in `kubernetes/` are deliberately separate from infrastructure provisioning.

## Architecture

```
 VPC A (existing) ---- peering ----\
 VPC B (existing) ---- peering ----- VPC C (new private EKS VPC) ---- peering ---- VPC D (existing)
                                      |-- four private subnets / four route tables
                                      |-- one EKS cluster (private API only)
                                      |-- node-1 api-1 | node-2 api-2 | node-3 api-2 | node-4 api-1
                                      `-- S3 gateway + selected Interface endpoints; no NAT gateway
```

Peering is non-transitive. VPC C can communicate with each peer using its own routes; this configuration never creates A-to-B, A-to-D, or B-to-D transit paths.

## Prerequisites

- Terraform `>= 1.10` (native S3 lockfiles require modern Terraform), AWS CLI, Python 3, and `kubectl` for manifest validation.
- Network approval for VPC C CIDR, four client account-specific AZ names, and every return route.
- An AWS identity with the permissions summarized in [docs/deployment-guide.md](docs/deployment-guide.md). No credentials are stored in this repository.
- Private network access to the EKS API from the operator environment. The EKS public endpoint is disabled.
- An existing, encrypted, versioned S3 state bucket. Create it through [bootstrap/](bootstrap/) first.

## Client inputs

Copy the examples; do not edit `.tf` files.

```bash
cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl
```

Obtain values from the following authoritative sources:

| Value | Where to obtain/confirm it |
|---|---|
| VPC A/B/D IDs and CIDRs | The owning network account's VPC console, CMDB, or `aws ec2 describe-vpcs`; obtain an approved IPv4 CIDR, not a guessed range. |
| Remote route-table IDs | The owner of the subnets that must return traffic to VPC C, using the VPC route-table console/CMDB or `aws ec2 describe-route-tables`. Never use a main route table by assumption. |
| Four AZ names | `aws ec2 describe-availability-zones --region us-east-1` in the **target account**. AZ name-to-physical-zone mapping is account-specific. |
| Peer owner account/region | The owner of each existing VPC. Confirm whether the Terraform execution identity may manage their route tables. |
| EKS version and node types | Current regional EKS support and approved platform standards immediately before deployment. |

`scripts/preflight-check.sh terraform.tfvars` checks four unique AZs, CIDR syntax, containment, and all overlaps without contacting AWS. The Terraform configuration repeats the network check at plan/apply time to prevent bypassing it.

## Initialize and validate

```bash
./scripts/preflight-check.sh terraform.tfvars
terraform init -backend-config=backend.hcl
./scripts/validate.sh
```

The validation script runs formatting checks, offline Terraform initialization, `terraform validate`, and Kubernetes kustomize rendering. It does not run a plan or apply.

## Plan and approved deployment

Only after change approval and an authorized AWS identity are available:

```bash
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform show tfplan
# After peer acceptance/route authorization and an explicit deployment approval:
terraform apply tfplan
```

For cross-account/external peering, the first approved apply creates a pending request, the VPC owner explicitly accepts it, and a subsequent approved apply creates routes after Terraform observes `active`. See [docs/networking.md](docs/networking.md). This repository has not run these commands against AWS.

## Kubernetes workload examples

After cluster access, image approval, and an application deployment approval, replace the invalid placeholder image locations and apply separately:

```bash
kubectl apply -k kubernetes/api-deployment-1
kubectl apply -k kubernetes/api-deployment-2
```

The examples pin API 1 to the `api-1` node pair (Nodes 1/4) and API 2 to `api-2` (Nodes 2/3), with required zone anti-affinity and topology spread. They are examples, not a production release pipeline.

## Safe destroy

Destruction can disrupt applications and peering. First remove workloads, load balancers, and dependent resources; obtain approval from VPC A/B/D owners; review a destruction plan; then use the same reviewed variable/backend files. Do not destroy a shared state bucket until every state using it has been migrated or intentionally retired.

More detail: [architecture](docs/architecture.md), [deployment guide](docs/deployment-guide.md), [networking](docs/networking.md), [security](docs/security.md), and [troubleshooting](docs/troubleshooting.md).
