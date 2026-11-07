data "aws_vpc_endpoint_service" "interface" {
  for_each = var.enabled ? var.interface_services : toset([])

  service_name = "com.amazonaws.${var.region}.${each.value}"
}

resource "aws_vpc_endpoint" "s3" {
  count = var.enabled && var.enable_s3_gateway_endpoint ? 1 : 0

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids

  tags = merge(var.tags, { Name = "s3-gateway" })
}

resource "aws_vpc_endpoint" "interface" {
  for_each = var.enabled ? var.interface_services : toset([])

  vpc_id              = var.vpc_id
  service_name        = data.aws_vpc_endpoint_service.interface[each.key].service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [var.endpoint_security_group_id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${each.value}-interface" })
}
