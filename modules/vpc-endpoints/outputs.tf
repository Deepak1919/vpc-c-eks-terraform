output "s3_gateway_endpoint_id" { value = try(aws_vpc_endpoint.s3[0].id, null) }
output "interface_endpoint_ids" { value = { for name, endpoint in aws_vpc_endpoint.interface : name => endpoint.id } }
