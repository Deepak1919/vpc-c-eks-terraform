resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id                  = var.vpc_id
  availability_zone       = each.value.availability_zone
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = format("private-%s", each.value.availability_zone)
    Tier = "private"
  })
}
