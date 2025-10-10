# =============================================================================
# REDIS ENTERPRISE EC2 INSTANCES
# =============================================================================
# Pure EC2 instance management for Redis Enterprise cluster nodes
# =============================================================================

# Platform-specific AMI selection
data "aws_ami" "ubuntu" {
  count       = var.platform == "ubuntu" ? 1 : 0
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_ami" "rhel" {
  count       = var.platform == "rhel" ? 1 : 0
  most_recent = true
  owners      = ["309956199498"] # Red Hat

  filter {
    name   = "name"
    values = ["RHEL-9.*_HVM-*-x86_64-*-Hourly2-GP2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Platform configuration
locals {
  platform_config = {
    ubuntu = {
      ami_id = var.platform == "ubuntu" ? data.aws_ami.ubuntu[0].id : null
      user   = "ubuntu"
    }
    rhel = {
      ami_id = var.platform == "rhel" ? data.aws_ami.rhel[0].id : null
      user   = "ec2-user"
    }
  }

  selected_config = local.platform_config[var.platform]
}

# Redis Enterprise cluster nodes
resource "aws_instance" "redis_enterprise_nodes" {
  count                  = var.node_count
  ami                    = local.selected_config.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [var.security_group_id]
  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]

  # Associate public IP for initial setup (disabled when using EIPs)
  associate_public_ip_address = var.use_elastic_ips ? false : var.associate_public_ip_address

  # Root volume configuration
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.node_root_size
    encrypted             = var.ebs_encryption_enabled
    delete_on_termination = true

    tags = merge(
      {
        Name    = "${var.user_prefix}-${var.cluster_name}-root-${count.index + 1}"
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
      Name      = "${var.user_prefix}-${var.cluster_name}-node-${count.index + 1}"
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

# =============================================================================
# ELASTIC IP ADDRESSES (OPTIONAL)
# =============================================================================

# Elastic IP addresses for Redis Enterprise nodes (optional)
resource "aws_eip" "redis_enterprise_eips" {
  count    = var.use_elastic_ips ? var.node_count : 0
  domain   = "vpc"
  instance = aws_instance.redis_enterprise_nodes[count.index].id

  tags = merge(
    {
      Name    = "${var.name_prefix}-redis-eip-${count.index + 1}"
      Owner   = var.owner
      Project = var.project
      Type    = "Redis-Enterprise-EIP"
    },
    var.tags
  )

  # Ensure instance is created before EIP
  depends_on = [aws_instance.redis_enterprise_nodes]
}