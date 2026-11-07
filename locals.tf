locals {
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    },
    var.tags,
  )

  private_subnets = {
    for index, cidr in var.private_subnet_cidrs :
    format("az-%d", index + 1) => {
      availability_zone = var.availability_zones[index]
      cidr_block        = cidr
      ordinal           = index + 1
    }
  }

  # This ordering is intentional: API pair 1 is in AZs 1 and 4, API pair 2
  # is in AZs 2 and 3. The supplied AZ names remain account-specific.
  node_groups = {
    node-1 = {
      subnet_key    = "az-1"
      workload_pair = "api-1"
    }
    node-2 = {
      subnet_key    = "az-2"
      workload_pair = "api-2"
    }
    node-3 = {
      subnet_key    = "az-3"
      workload_pair = "api-2"
    }
    node-4 = {
      subnet_key    = "az-4"
      workload_pair = "api-1"
    }
  }

  peer_vpcs = {
    a = {
      vpc_id               = var.vpc_a_id
      cidr_block           = var.vpc_a_cidr
      route_table_ids      = var.vpc_a_route_table_ids
      peer_owner_id        = var.vpc_a_peer_owner_id
      peer_region          = var.vpc_a_peer_region
      acceptance_mode      = var.vpc_a_acceptance_mode
      manage_remote_routes = var.vpc_a_manage_remote_routes
    }
    b = {
      vpc_id               = var.vpc_b_id
      cidr_block           = var.vpc_b_cidr
      route_table_ids      = var.vpc_b_route_table_ids
      peer_owner_id        = var.vpc_b_peer_owner_id
      peer_region          = var.vpc_b_peer_region
      acceptance_mode      = var.vpc_b_acceptance_mode
      manage_remote_routes = var.vpc_b_manage_remote_routes
    }
    d = {
      vpc_id               = var.vpc_d_id
      cidr_block           = var.vpc_d_cidr
      route_table_ids      = var.vpc_d_route_table_ids
      peer_owner_id        = var.vpc_d_peer_owner_id
      peer_region          = var.vpc_d_peer_region
      acceptance_mode      = var.vpc_d_acceptance_mode
      manage_remote_routes = var.vpc_d_manage_remote_routes
    }
  }
}
