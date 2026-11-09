output "route_table_ids" {
  value = { for key, route_table in aws_route_table.private : key => route_table.id }
}
