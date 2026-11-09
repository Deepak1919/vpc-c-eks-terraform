# Security model

The EKS Kubernetes API has private access only. There is no public SSH rule and no `0.0.0.0/0` ingress rule. IAM roles use AWS managed EKS policies necessary for the control plane and node bootstrap; applications should use narrowly scoped IRSA or Pod Identity roles rather than node credentials.

## Security-group flows

| Source | Destination | Protocol/port | Why |
|---|---|---|---|
| Worker nodes / VPC-CNI pods | EKS control-plane SG | TCP 443 | Kubernetes API. |
| `trusted_cidrs` only | EKS control-plane SG | TCP 443 | Private administration. |
| EKS control-plane SG | Worker-node SG | TCP 10250 | Kubelet health/exec traffic. |
| EKS control-plane SG | Worker-node SG | TCP 443 | Control-plane webhook traffic. |
| Worker-node SG | Worker-node SG | all protocols | Required scoped node/pod east-west traffic; it is SG-to-self, not CIDR-wide. |
| Worker nodes / VPC-CNI pods | Interface-endpoint SG | TCP 443 | ECR, STS, Logs and configured AWS APIs. |
| Worker-node SG | AWS S3 managed prefix list | TCP 443 | Private S3 Gateway endpoint, including ECR image-layer retrieval. |
| Worker-node SG | VPC resolver | UDP/TCP 53 | Private DNS lookups. |
| Interface-endpoint SG | VPC C CIDR | all protocols | Stateful response paths only. |

Extra private CIDR ingress is possible only via `additional_security_group_rules` and only when both ports are present in `allowed_ports`. It cannot use the public Internet CIDR. Carefully review any addition; it is an intentional exception to the base flow table.

The EKS control plane sends API, audit, authenticator, controller manager, and scheduler logs to CloudWatch. A customer-managed KMS key can be configured for Kubernetes secret envelope encryption. Node launch templates force encrypted gp3 root volumes and IMDSv2. For regulated environments, also enable organization-wide EBS default encryption with an approved CMK, centralize CloudWatch retention, apply SCPs, and assess GuardDuty/CloudTrail/Config requirements.
