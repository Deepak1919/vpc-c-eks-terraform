data "external" "cidr_validation" {
  program = ["python3", "${path.root}/scripts/cidr_validate.py"]

  query = {
    vpc_cidr             = var.vpc_cidr
    private_subnets_json = jsonencode(var.private_subnet_cidrs)
    remote_cidrs_json    = jsonencode([var.vpc_a_cidr, var.vpc_b_cidr, var.vpc_d_cidr])
    availability_zones   = jsonencode(var.availability_zones)
  }
}

resource "terraform_data" "configuration_validation" {
  input = data.external.cidr_validation.result

  lifecycle {
    precondition {
      condition     = data.external.cidr_validation.result.valid == "true"
      error_message = "Network configuration is invalid: ${data.external.cidr_validation.result.diagnostics}"
    }

    precondition {
      condition     = length(var.availability_zones) == 4 && length(distinct(var.availability_zones)) == 4
      error_message = "Exactly four distinct, account-specific Availability Zone names are required."
    }
  }
}

module "vpc" {
  source = "./modules/vpc"

  name       = var.vpc_name
  cidr_block = var.vpc_cidr
  tags       = local.common_tags

  depends_on = [terraform_data.configuration_validation]
}

module "subnets" {
  source = "./modules/subnets"

  vpc_id          = module.vpc.id
  private_subnets = local.private_subnets
  tags            = local.common_tags
}

module "route_tables" {
  source = "./modules/route-tables"

  vpc_id          = module.vpc.id
  private_subnets = module.subnets.private_subnets
  tags            = local.common_tags
}

module "security_groups" {
  source = "./modules/security-groups"

  vpc_id                          = module.vpc.id
  vpc_cidr                        = var.vpc_cidr
  region                          = var.aws_region
  trusted_cidrs                   = var.trusted_cidrs
  allowed_ports                   = var.allowed_ports
  additional_security_group_rules = var.additional_security_group_rules
  tags                            = local.common_tags
}

module "iam" {
  source = "./modules/iam"

  name_prefix = var.eks_cluster_name
  tags        = local.common_tags
}

module "eks" {
  source = "./modules/eks"

  cluster_name              = var.eks_cluster_name
  kubernetes_version        = var.eks_kubernetes_version
  cluster_role_arn          = module.iam.cluster_role_arn
  subnet_ids                = values(module.subnets.private_subnet_ids)
  cluster_security_group_id = module.security_groups.cluster_security_group_id
  enabled_log_types         = var.eks_enabled_log_types
  log_retention_in_days     = var.eks_log_retention_in_days
  kms_key_arn               = var.eks_secrets_kms_key_arn
  tags                      = local.common_tags

  depends_on = [module.iam]
}

module "vpc_endpoints" {
  source = "./modules/vpc-endpoints"

  enabled                    = var.enable_vpc_endpoints
  vpc_id                     = module.vpc.id
  region                     = var.aws_region
  subnet_ids                 = values(module.subnets.private_subnet_ids)
  route_table_ids            = values(module.route_tables.route_table_ids)
  endpoint_security_group_id = module.security_groups.endpoint_security_group_id
  enable_s3_gateway_endpoint = var.enable_s3_gateway_endpoint
  interface_services         = var.interface_endpoint_services
  tags                       = local.common_tags
}

module "eks_node_groups" {
  source = "./modules/eks-node-groups"

  cluster_name  = module.eks.cluster_name
  node_role_arn = module.iam.node_role_arn
  node_groups = {
    for name, node_group in local.node_groups : name => merge(node_group, {
      subnet_id = module.subnets.private_subnet_ids[node_group.subnet_key]
    })
  }
  instance_types       = var.node_instance_types
  disk_size            = var.node_disk_size
  desired_size         = var.node_desired_size
  min_size             = var.node_min_size
  max_size             = var.node_max_size
  capacity_type        = var.node_capacity_type
  additional_node_tags = var.node_group_tags
  tags                 = local.common_tags

  depends_on = [module.eks, module.vpc_endpoints]
}

module "vpc_peering" {
  source = "./modules/vpc-peering"

  enabled                   = var.enable_vpc_peering
  requester_vpc_id          = module.vpc.id
  requester_cidr_block      = var.vpc_cidr
  requester_region          = var.aws_region
  requester_route_table_ids = values(module.route_tables.route_table_ids)
  peers                     = local.peer_vpcs
  tags                      = local.common_tags

  depends_on = [module.route_tables]
}
