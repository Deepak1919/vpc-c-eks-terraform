output "connection_ids" { value = { for key, connection in aws_vpc_peering_connection.requester : key => connection.id } }
