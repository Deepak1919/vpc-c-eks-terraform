output "private_subnet_ids" {
  value = { for key, subnet in aws_subnet.private : key => subnet.id }
}

output "private_subnets" {
  value = {
    for key, subnet in aws_subnet.private : key => {
      id                = subnet.id
      availability_zone = subnet.availability_zone
      cidr_block        = subnet.cidr_block
    }
  }
}
