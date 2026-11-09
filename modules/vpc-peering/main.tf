locals {
  active_peers = var.enabled ? var.peers : {}

  requester_routes = {
    for route in flatten([
      for peer_name, peer in local.active_peers : [
        for route_table_id in var.requester_route_table_ids : {
          key            = "${peer_name}-${route_table_id}"
          peer_name      = peer_name
          route_table_id = route_table_id
          destination    = peer.cidr_block
        }
      ]
      ]) : route.key => {
      peer_name      = route.peer_name
      route_table_id = route.route_table_id
      destination    = route.destination
    }
  }

  remote_routes = {
    for route in flatten([
      for peer_name, peer in local.active_peers : peer.manage_remote_routes ? [
        for route_table_id in peer.route_table_ids : {
          key            = "${peer_name}-${route_table_id}"
          peer_name      = peer_name
          route_table_id = route_table_id
        }
      ] : []
      ]) : route.key => {
      peer_name      = route.peer_name
      route_table_id = route.route_table_id
    }
  }
}

resource "aws_vpc_peering_connection" "requester" {
  for_each = local.active_peers

  vpc_id        = var.requester_vpc_id
  peer_vpc_id   = each.value.vpc_id
  peer_owner_id = each.value.peer_owner_id
  peer_region   = each.value.peer_region
  auto_accept   = each.value.acceptance_mode == "auto"

  tags = merge(var.tags, {
    Name = "vpc-c-to-vpc-${upper(each.key)}"
  })

  lifecycle {
    precondition {
      condition     = !(each.value.acceptance_mode == "auto" && each.value.peer_region != null)
      error_message = "auto acceptance is supported only by compatible same-account, same-region requests. Omit peer_region and use external for cross-account or inter-region peering."
    }
  }
}

# For external acceptance, Terraform creates only the connection request first.
# These preconditions prevent any route from being created until the AWS status
# has become active; accept the request in the peer account and re-run apply.
resource "aws_route" "requester_to_peer" {
  for_each = local.requester_routes

  route_table_id            = each.value.route_table_id
  destination_cidr_block    = each.value.destination
  vpc_peering_connection_id = aws_vpc_peering_connection.requester[each.value.peer_name].id

  lifecycle {
    precondition {
      condition     = aws_vpc_peering_connection.requester[each.value.peer_name].accept_status == "active"
      error_message = "Peering ${each.value.peer_name} is not active. Accept it in the peer account, then run Terraform again."
    }
  }
}

resource "aws_route" "peer_to_requester" {
  for_each = local.remote_routes

  route_table_id            = each.value.route_table_id
  destination_cidr_block    = var.requester_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.requester[each.value.peer_name].id

  lifecycle {
    precondition {
      condition     = aws_vpc_peering_connection.requester[each.value.peer_name].accept_status == "active"
      error_message = "Peering ${each.value.peer_name} is not active. Remote return routes are withheld until acceptance."
    }
  }
}
