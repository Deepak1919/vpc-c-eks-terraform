variable "cluster_name" { type = string }
variable "node_role_arn" { type = string }
variable "node_groups" {
  type = map(object({
    subnet_key    = string
    subnet_id     = string
    workload_pair = string
  }))
}
variable "instance_types" { type = list(string) }
variable "disk_size" { type = number }
variable "desired_size" { type = number }
variable "min_size" { type = number }
variable "max_size" { type = number }
variable "capacity_type" { type = string }
variable "additional_node_tags" { type = map(string) }
variable "tags" { type = map(string) }
