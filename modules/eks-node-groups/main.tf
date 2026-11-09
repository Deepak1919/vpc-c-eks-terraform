resource "aws_launch_template" "node" {
  for_each = var.node_groups

  name_prefix            = "${var.cluster_name}-${each.key}-"
  update_default_version = true

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.disk_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, var.additional_node_tags, {
      Name = "${var.cluster_name}-${each.key}"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, var.additional_node_tags, {
      Name = "${var.cluster_name}-${each.key}"
    })
  }

  tags = merge(var.tags, var.additional_node_tags, {
    Name = "${var.cluster_name}-${each.key}"
  })
}

resource "aws_eks_node_group" "this" {
  for_each = var.node_groups

  cluster_name    = var.cluster_name
  node_group_name = each.key
  node_role_arn   = var.node_role_arn
  subnet_ids      = [each.value.subnet_id]

  instance_types = var.instance_types
  capacity_type  = var.capacity_type

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    "workload-pair" = each.value.workload_pair
    "node-group"    = each.key
  }

  launch_template {
    id      = aws_launch_template.node[each.key].id
    version = tostring(aws_launch_template.node[each.key].latest_version)
  }

  tags = merge(var.tags, var.additional_node_tags, {
    Name = "${var.cluster_name}-${each.key}"
  })

  lifecycle {
    precondition {
      condition     = var.min_size <= var.desired_size && var.desired_size <= var.max_size
      error_message = "node_min_size <= node_desired_size <= node_max_size is required."
    }
  }
}
