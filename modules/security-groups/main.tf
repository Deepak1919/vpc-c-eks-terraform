resource "aws_security_group" "cluster" {
  name_prefix = "eks-control-plane-"
  description = "Restricted ingress to the private EKS control plane"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "eks-control-plane" })
}

resource "aws_security_group" "nodes" {
  name_prefix = "eks-worker-nodes-"
  description = "EKS managed node and workload traffic"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "eks-worker-nodes" })
}

resource "aws_security_group" "endpoints" {
  name_prefix = "vpc-interface-endpoints-"
  description = "HTTPS ingress to Interface VPC endpoints from EKS nodes and pods"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "vpc-interface-endpoints" })
}

data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${var.region}.s3"
}

# Nodes and pods using the VPC CNI share the node security group. This allows
# the private API endpoint to be reached without opening it to the internet.
resource "aws_vpc_security_group_ingress_rule" "cluster_from_nodes_api" {
  security_group_id            = aws_security_group.cluster.id
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "Kubernetes API from worker nodes and VPC-CNI pods"
}

resource "aws_vpc_security_group_ingress_rule" "cluster_from_trusted" {
  for_each = toset(var.trusted_cidrs)

  security_group_id = aws_security_group.cluster.id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "Private administrative access to Kubernetes API"
}

resource "aws_vpc_security_group_egress_rule" "cluster_to_nodes_kubelet" {
  security_group_id            = aws_security_group.cluster.id
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "tcp"
  from_port                    = 10250
  to_port                      = 10250
  description                  = "Control plane kubelet health and exec traffic"
}

resource "aws_vpc_security_group_egress_rule" "cluster_to_nodes_https" {
  security_group_id            = aws_security_group.cluster.id
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "Control plane webhook traffic to nodes"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_from_cluster_kubelet" {
  security_group_id            = aws_security_group.nodes.id
  referenced_security_group_id = aws_security_group.cluster.id
  ip_protocol                  = "tcp"
  from_port                    = 10250
  to_port                      = 10250
  description                  = "Kubelet API from EKS control plane"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_from_cluster_https" {
  security_group_id            = aws_security_group.nodes.id
  referenced_security_group_id = aws_security_group.cluster.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "Webhook HTTPS from EKS control plane"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_self" {
  security_group_id            = aws_security_group.nodes.id
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "-1"
  description                  = "Required node-to-node and pod-to-pod traffic within the EKS worker security group"
}

resource "aws_vpc_security_group_egress_rule" "nodes_to_cluster_api" {
  security_group_id            = aws_security_group.nodes.id
  referenced_security_group_id = aws_security_group.cluster.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "Kubernetes API from nodes"
}

resource "aws_vpc_security_group_egress_rule" "nodes_to_endpoints_https" {
  security_group_id            = aws_security_group.nodes.id
  referenced_security_group_id = aws_security_group.endpoints.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "AWS Interface endpoint HTTPS from nodes and VPC-CNI pods"
}

# A Gateway endpoint has no security group. The AWS-managed S3 prefix list
# constrains ECR layer and approved S3 traffic to the gateway endpoint range.
resource "aws_vpc_security_group_egress_rule" "nodes_to_s3" {
  security_group_id = aws_security_group.nodes.id
  prefix_list_id    = data.aws_prefix_list.s3.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "HTTPS to Amazon S3 through the Gateway endpoint"
}

resource "aws_vpc_security_group_egress_rule" "nodes_to_vpc_dns" {
  security_group_id = aws_security_group.nodes.id
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "udp"
  from_port         = 53
  to_port           = 53
  description       = "DNS queries to the VPC resolver"
}

resource "aws_vpc_security_group_egress_rule" "nodes_to_vpc_dns_tcp" {
  security_group_id = aws_security_group.nodes.id
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 53
  to_port           = 53
  description       = "Large DNS responses to the VPC resolver"
}

resource "aws_vpc_security_group_ingress_rule" "endpoints_from_nodes" {
  security_group_id            = aws_security_group.endpoints.id
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "AWS Interface endpoint HTTPS from authorized EKS nodes and pods"
}

resource "aws_vpc_security_group_egress_rule" "endpoints_response" {
  security_group_id = aws_security_group.endpoints.id
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "-1"
  description       = "Return traffic to private workloads"
}

resource "aws_vpc_security_group_ingress_rule" "additional" {
  for_each = { for index, rule in var.additional_security_group_rules : index => rule }

  security_group_id = each.value.target == "cluster" ? aws_security_group.cluster.id : aws_security_group.nodes.id
  cidr_ipv4         = each.value.cidr_ipv4
  ip_protocol       = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  description       = each.value.description

  lifecycle {
    precondition {
      condition     = contains(var.allowed_ports, each.value.from_port) && contains(var.allowed_ports, each.value.to_port)
      error_message = "Every additional ingress port must be included in allowed_ports."
    }
  }
}
