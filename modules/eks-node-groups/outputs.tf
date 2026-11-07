output "node_group_names" {
  value = {
    for name, node_group in aws_eks_node_group.this : name => {
      name          = node_group.node_group_name
      workload_pair = var.node_groups[name].workload_pair
      subnet_key    = var.node_groups[name].subnet_key
    }
  }
}
