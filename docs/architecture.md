# Architecture and design decisions

VPC C is the only new network. It has four private subnets, one in each client-supplied AZ, and exactly one dedicated route table per subnet. `private_subnet_cidrs` and `availability_zones` are paired by index, so the client controls the AZ names rather than relying on account-independent AZ letters.

The EKS private API uses all four subnets. Each managed node group, however, receives a single subnet only:

| Node group | Subnet/AZ input position | Required label | Workload |
|---|---:|---|---|
| `node-1` | 1 | `workload-pair=api-1` | API deployment 1 |
| `node-2` | 2 | `workload-pair=api-2` | API deployment 2 |
| `node-3` | 3 | `workload-pair=api-2` | API deployment 2 |
| `node-4` | 4 | `workload-pair=api-1` | API deployment 1 |

The initial value `node_desired_size = 1` produces four worker nodes. The field remains configurable so capacity can be increased deliberately; changing it above one means there are more than four workers, not more node groups.

The API manifest examples require their matching label, require two replicas to occupy distinct zones, and use `DoNotSchedule` topology constraints. Thus an AZ-A loss leaves the API 1 replica eligible only in AZ-D; B/C similarly protect API 2. This is scheduling intent, not an unconditional HA guarantee.

Recovery additionally depends on all of the following:

- A surviving node in the remaining paired AZ has enough allocatable CPU/memory for both replicas, or that single-AZ node group can scale up.
- Cluster Autoscaler (not installed by this template) is deployed, configured to discover these node groups, has IAM permission, and can obtain capacity in the surviving AZ.
- The surviving subnet has available IP addresses for nodes, pods, endpoint ENIs, and any load balancers.
- The selected instance type has regional/AZ EC2 capacity and service dependencies, including endpoints, remain reachable.
- Application readiness, data dependencies, PDBs, and the external traffic path permit failover.

Managed node group autoscaling never moves capacity from a failed AZ's group to another group. Set a tested min/max and reserve enough IP/capacity in each surviving pair member; test AZ impairment in a non-production environment.
