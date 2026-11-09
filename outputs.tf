output "vpc_c_id" {
  description = "ID of the new Application/EKS VPC (VPC C)."
  value       = module.vpc.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs keyed by configured AZ position."
  value       = module.subnets.private_subnet_ids
}

output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Private EKS Kubernetes API endpoint. Treat as sensitive operational information."
  value       = module.eks.cluster_endpoint
}

output "node_group_names" {
  description = "The four managed node group names and their API-pair placement."
  value       = module.eks_node_groups.node_group_names
}

output "vpc_peering_connection_ids" {
  description = "Peering connection IDs keyed by remote VPC letter. External acceptance may still be required."
  value       = module.vpc_peering.connection_ids
}
