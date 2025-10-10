# =============================================================================
# REDIS ENTERPRISE EC2 INSTANCES
# =============================================================================
# Pure EC2 instance management for Redis Enterprise cluster nodes
# =============================================================================

# Redis Enterprise cluster nodes
resource "aws_instance" "redis_enterprise_nodes" {
  count                  = var.node_count
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [var.security_group_id]
  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]

  # Associate public IP for initial setup (can be disabled later for production)
  associate_public_ip_address = var.associate_public_ip_address

  # Root volume configuration
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.node_root_size
    encrypted             = var.ebs_encryption_enabled
    delete_on_termination = true

    tags = merge(
      {
        Name    = "${var.name_prefix}-redis-root-${count.index + 1}"
        Owner   = var.owner
        Project = var.project
      },
      var.tags
    )
  }

  # User data for basic system setup
  user_data = var.user_data_base64

  tags = merge(
    {
      Name      = "${var.name_prefix}-redis-node-${count.index + 1}"
      Owner     = var.owner
      Project   = var.project
      Type      = "Redis-Enterprise-Node"
      Role      = count.index == 0 ? "primary" : "replica"
      NodeIndex = count.index
    },
    var.tags
  )

  # Ensure instances are created one at a time to avoid race conditions
  lifecycle {
    create_before_destroy = true
  }

  # Wait for instance to be ready before moving to next resource
  depends_on = [
    # No specific dependencies - pure infrastructure
  ]
}