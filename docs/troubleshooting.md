# Troubleshooting

| Symptom | Likely cause and response |
|---|---|
| Preflight reports CIDR overlap | Correct the approved VPC/subnet CIDR inputs. Do not weaken the check; route destination ambiguity breaks private connectivity. |
| Terraform says a peering is not active | The owner has not accepted an external request, or acceptance is in the wrong account/region. Accept it, confirm the request ID, then re-run the approved workflow. |
| Remote route authorization fails | The Terraform role lacks access to the existing route table. Set `*_manage_remote_routes = false` and have the remote owner install the documented VPC C return route, or obtain explicit authorization. |
| Nodes do not join | Check EKS API reachability, endpoint private DNS, endpoint SG TCP/443, ECR/S3 access, node IAM policies, subnet IP availability, and the node group's AZ capacity. |
| Pods remain Pending after an AZ event | Inspect node affinity/topology constraints, the surviving paired node group size, pod resource requests, PDBs, Cluster Autoscaler logs, EC2 capacity, and available subnet IPs. Autoscaling does not shift failed-AZ capacity to another node group. |
| Image pulls or STS calls time out | Verify enabled endpoints, Private DNS, node-to-endpoint TCP/443 SG flow, the endpoint ENIs' subnets, and whether the workload uses an unlisted AWS service. |
| `kubectl` cannot reach the cluster | The cluster endpoint is private. Run from an approved private network with DNS/route/SG access; do not enable a public endpoint as a troubleshooting shortcut. |
| Endpoint creation fails | Confirm the chosen service exists in us-east-1 and that VPC DNS support/hostnames are enabled. Remove unneeded custom endpoint names. |

Collect evidence before changing security groups or routes: Terraform plan, CloudTrail events, EKS/node-group status, VPC Flow Logs where enabled, CloudWatch logs, route-table screenshots/exports, and DNS results from an authorized private host.
