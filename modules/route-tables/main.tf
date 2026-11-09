resource "aws_route_table" "private" {
  for_each = var.private_subnets

  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name = format("private-%s", each.value.availability_zone)
    Tier = "private"
  })
}

resource "aws_route_table_association" "private" {
  for_each = var.private_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
