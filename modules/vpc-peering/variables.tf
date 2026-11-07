variable "enabled" { type = bool }
variable "requester_vpc_id" { type = string }
variable "requester_cidr_block" { type = string }
variable "requester_region" { type = string }
variable "requester_route_table_ids" { type = list(string) }
variable "peers" {
  type = map(object({
    vpc_id               = string
    cidr_block           = string
    route_table_ids      = list(string)
    peer_owner_id        = string
    peer_region          = string
    acceptance_mode      = string
    manage_remote_routes = bool
  }))
}
variable "tags" { type = map(string) }
