# Networking and private connectivity

## Peering and routes

The `vpc-peering` module creates one requester connection from VPC C to each of A, B, and D. For every VPC C private route table it creates a route to the corresponding remote CIDR. If `*_manage_remote_routes = true`, it also creates the configured return route from every explicitly named remote route table to VPC C.

There is no route from one remote CIDR through VPC C to another remote CIDR. AWS VPC peering is non-transitive and this template never adds a Transit Gateway.

`external` acceptance mode is the safe default. Terraform creates a pending request but its route resources have a precondition on the peering connection's `active` status. The accepter must:

1. Verify requester/peer VPC IDs, CIDRs, owner account, region, and DNS-resolution requirements.
2. Accept the request in the peer account/region.
3. Enable the peer-side DNS resolution option if private DNS resolution across the connection is required and policy permits it.
4. Either authorize the deployment identity to manage the supplied remote route tables or add VPC C return routes manually. Set `*_manage_remote_routes = false` when remote routes are intentionally operated outside this Terraform state.
5. Re-run the approved Terraform workflow so requester and authorized return routes are created only after the connection is active.

For cross-account peers, `peer_owner_id` is mandatory and `peer_region` is configurable (omit it only when the peer is in the configured AWS region). This module does not pretend that one account can accept or modify another account's resources. `auto` is valid only for compatible same-account/same-region connections, and requires omitting `peer_region`; AWS will reject unsupported use.

## No NAT Gateway

All VPC C subnets are private and no NAT or Internet Gateway route is created. The default endpoint set is intentionally limited to the operational dependencies named in the requirements:

| Endpoint | Reason |
|---|---|
| S3 Gateway | Private S3 access without hourly Interface endpoint cost. |
| ECR API and Docker | Private image authorization and layer pulls. |
| CloudWatch Logs | Node/application log delivery when configured. |
| STS | IAM credential exchanges, including IRSA-style workloads. |
| EC2, Autoscaling | Cluster Autoscaler or related node-management calls when installed. |
| Elastic Load Balancing | AWS Load Balancer Controller when installed. |

Endpoint availability is checked by the AWS endpoint-service data source when Terraform plans in `us-east-1`; invalid endpoint service names fail before endpoint creation. Interface endpoint security groups permit TCP/443 only from the worker security group, which also covers VPC-CNI pod traffic.

Add `eks-auth` only when using EKS Pod Identity. Add `eks` only when private workloads call the EKS service API. These are not created by default to avoid unnecessary interface endpoint cost and attack surface.

Other dependencies still need explicit approved connectivity: external SaaS/API endpoints, public package repositories, third-party registries, Secrets Manager/KMS/SSM services, internal DNS forwarders, on-premises networks, and any load-balancer/ingress path. Meet each need through a required endpoint, private connectivity, or an approved egress architecture; this template does not provide implicit Internet egress.
