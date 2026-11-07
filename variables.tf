variable "aws_region" {
  description = "AWS Region for VPC C. This architecture is designed for us-east-1."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "This template's validated endpoint set and four-AZ design target us-east-1."

  }
}

variable "environment" {
  description = "Deployment environment, for example prod."
  type        = string
}

variable "project_name" {
  description = "Short project identifier used in standard tags."
  type        = string
}

variable "vpc_name" {
  description = "Name tag for VPC C."
  type        = string
}

variable "vpc_cidr" {
  description = "Non-overlapping IPv4 CIDR block for VPC C."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."

  }
}

variable "availability_zones" {
  description = "Exactly four distinct AWS account-specific AZ names in us-east-1, in Node 1 through Node 4 order."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) == 4 && length(distinct(var.availability_zones)) == 4
    error_message = "availability_zones must contain exactly four distinct AZ names."

  }
}

variable "private_subnet_cidrs" {
  description = "Exactly four non-overlapping private subnet CIDRs, aligned by index with availability_zones."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) == 4 && alltrue([for cidr in var.private_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "private_subnet_cidrs must contain exactly four valid IPv4 CIDR blocks."

  }
}

variable "vpc_a_id" {
  description = "Existing Bank Connectivity VPC (VPC A) ID."
  type        = string
}
variable "vpc_a_cidr" {
  description = "Existing VPC A IPv4 CIDR."
  type        = string
}
variable "vpc_a_route_table_ids" {
  description = "Authorized VPC A route table IDs for return routes."
  type        = list(string)
}
variable "vpc_a_peer_owner_id" {
  description = "AWS account ID that owns VPC A. Required even for same-account peering."
  type        = string
}
variable "vpc_a_peer_region" {
  description = "AWS Region of VPC A; null uses aws_region."
  type        = string
  default     = null
  nullable    = true
}
variable "vpc_a_acceptance_mode" {
  description = "auto only for compatible same-account peering; external requires explicit accepter action."
  type        = string
  default     = "external"
  validation {
    condition     = contains(["auto", "external"], var.vpc_a_acceptance_mode)
    error_message = "Use auto or external."
  }
}
variable "vpc_a_manage_remote_routes" {
  description = "Whether this deployment identity is authorized to write supplied VPC A route tables."
  type        = bool
  default     = true
}

variable "vpc_b_id" {
  description = "Existing NPCI Connectivity VPC (VPC B) ID."
  type        = string
}
variable "vpc_b_cidr" {
  description = "Existing VPC B IPv4 CIDR."
  type        = string
}
variable "vpc_b_route_table_ids" {
  description = "Authorized VPC B route table IDs for return routes."
  type        = list(string)
}
variable "vpc_b_peer_owner_id" {
  description = "AWS account ID that owns VPC B."
  type        = string
}
variable "vpc_b_peer_region" {
  description = "AWS Region of VPC B; null uses aws_region."
  type        = string
  default     = null
  nullable    = true
}
variable "vpc_b_acceptance_mode" {
  description = "auto only for compatible same-account peering; external requires explicit accepter action."
  type        = string
  default     = "external"
  validation {
    condition     = contains(["auto", "external"], var.vpc_b_acceptance_mode)
    error_message = "Use auto or external."
  }
}
variable "vpc_b_manage_remote_routes" {
  description = "Whether this deployment identity is authorized to write supplied VPC B route tables."
  type        = bool
  default     = true
}

variable "vpc_d_id" {
  description = "Existing Database VPC (VPC D) ID."
  type        = string
}
variable "vpc_d_cidr" {
  description = "Existing VPC D IPv4 CIDR."
  type        = string
}
variable "vpc_d_route_table_ids" {
  description = "Authorized VPC D route table IDs for return routes."
  type        = list(string)
}
variable "vpc_d_peer_owner_id" {
  description = "AWS account ID that owns VPC D."
  type        = string
}
variable "vpc_d_peer_region" {
  description = "AWS Region of VPC D; null uses aws_region."
  type        = string
  default     = null
  nullable    = true
}
variable "vpc_d_acceptance_mode" {
  description = "auto only for compatible same-account peering; external requires explicit accepter action."
  type        = string
  default     = "external"
  validation {
    condition     = contains(["auto", "external"], var.vpc_d_acceptance_mode)
    error_message = "Use auto or external."
  }
}
variable "vpc_d_manage_remote_routes" {
  description = "Whether this deployment identity is authorized to write supplied VPC D route tables."
  type        = bool
  default     = true
}

variable "enable_vpc_peering" {
  description = "Create the three VPC C peering connections and authorized routes."
  type        = bool
  default     = true
}
variable "enable_vpc_endpoints" {
  description = "Create private VPC endpoints required in the no-NAT design."
  type        = bool
  default     = true
}
variable "enable_s3_gateway_endpoint" {
  description = "Attach the S3 Gateway endpoint to all VPC C private route tables."
  type        = bool
  default     = true
}

variable "interface_endpoint_services" {
  description = "Short service names for necessary Interface endpoints. Add eks-auth only when using EKS Pod Identity and eks only when private workloads call the EKS API."
  type        = set(string)
  default     = ["ecr.api", "ecr.dkr", "logs", "sts", "ec2", "elasticloadbalancing", "autoscaling"]

  validation {
    condition     = alltrue([for service in var.interface_endpoint_services : can(regex("^[a-z0-9.-]+$", service))])
    error_message = "Interface endpoint service names must be short AWS service names, such as ecr.api."

  }
}

variable "eks_cluster_name" {
  description = "EKS cluster name."
  type        = string
}
variable "eks_kubernetes_version" {
  description = "Supported EKS Kubernetes version approved for this account and region."
  type        = string
}
variable "eks_enabled_log_types" {
  description = "EKS control-plane log types sent to CloudWatch."
  type        = set(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}
variable "eks_log_retention_in_days" {
  description = "Retention for the EKS control-plane CloudWatch log group."
  type        = number
  default     = 90
}
variable "eks_secrets_kms_key_arn" {
  description = "Optional customer-managed KMS key ARN for EKS Kubernetes secret envelope encryption."
  type        = string
  default     = null
  nullable    = true
}

variable "node_instance_types" {
  description = "Allowed instance types for every managed node group."
  type        = list(string)
}
variable "node_disk_size" {
  description = "Encrypted root EBS volume size in GiB for node launch templates."
  type        = number
}
variable "node_desired_size" {
  description = "Initial desired nodes per node group. Use 1 to start with exactly four nodes."
  type        = number
  default     = 1
}
variable "node_min_size" {
  description = "Minimum nodes per node group."
  type        = number
  default     = 1
}
variable "node_max_size" {
  description = "Maximum nodes per node group."
  type        = number
  default     = 2
}
variable "node_capacity_type" {
  description = "EKS managed node capacity type."
  type        = string
  default     = "ON_DEMAND"
  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "node_capacity_type must be ON_DEMAND or SPOT."
  }
}
variable "node_group_tags" {
  description = "Additional tags placed on managed node groups and launch templates."
  type        = map(string)
  default     = {}
}

variable "trusted_cidrs" {
  description = "Private administrative or inspection CIDRs allowed to reach the private EKS API on TCP 443. Never use 0.0.0.0/0."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.trusted_cidrs : can(cidrnetmask(cidr)) && cidr != "0.0.0.0/0"])
    error_message = "trusted_cidrs must contain valid IPv4 CIDRs and must not include 0.0.0.0/0."

  }
}

variable "allowed_ports" {
  description = "Port allow-list for explicitly configured additional private ingress rules. Required platform rules are defined by the module."
  type        = set(number)
  default     = [443, 10250]
}

variable "additional_security_group_rules" {
  description = "Explicit, private CIDR-based ingress exceptions. target must be cluster or nodes; 0.0.0.0/0 is rejected."
  type = list(object({
    target      = string
    protocol    = string
    from_port   = number
    to_port     = number
    cidr_ipv4   = string
    description = string

  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.additional_security_group_rules :
      contains(["cluster", "nodes"], rule.target) &&
      rule.cidr_ipv4 != "0.0.0.0/0" &&
      can(cidrnetmask(rule.cidr_ipv4)) &&
      rule.from_port >= 0 && rule.to_port >= rule.from_port
    ])
    error_message = "Additional security group rules must target cluster/nodes, use a valid non-public CIDR, and have valid port ranges."

  }
}

variable "tags" {
  description = "Additional client tags, for example Owner and CostCenter."
  type        = map(string)
  default     = {}
}
