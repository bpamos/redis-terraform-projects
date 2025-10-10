# =============================================================================
# EBS STORAGE MODULE
# =============================================================================
# Manages EBS volumes and attachments for Redis Enterprise nodes
# =============================================================================

# Get subnet information for availability zone placement
data "aws_subnet" "selected" {
  count = var.node_count
  id    = var.subnet_ids[count.index % length(var.subnet_ids)]
}

# =============================================================================
# DATA VOLUMES
# =============================================================================

# Data volume for each Redis Enterprise node
resource "aws_ebs_volume" "redis_data" {
  count             = var.node_count
  availability_zone = data.aws_subnet.selected[count.index].availability_zone
  size              = var.data_volume_size
  type              = var.data_volume_type
  encrypted         = var.ebs_encryption_enabled
  
  tags = merge(
    {
      Name    = "${var.user_prefix}-${var.cluster_name}-data-${count.index + 1}"
      Owner   = var.owner
      Project = var.project
      Type    = "Redis-Data-Volume"
    },
    var.tags
  )
}

# Attach data volumes to Redis Enterprise nodes
resource "aws_volume_attachment" "redis_data_attachment" {
  count       = var.node_count
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.redis_data[count.index].id
  instance_id = var.instance_ids[count.index]
  
  depends_on = [aws_ebs_volume.redis_data]
}

# =============================================================================
# PERSISTENT VOLUMES
# =============================================================================

# Persistent storage volume for each Redis Enterprise node
resource "aws_ebs_volume" "redis_persistent" {
  count             = var.node_count
  availability_zone = data.aws_subnet.selected[count.index].availability_zone
  size              = var.persistent_volume_size
  type              = var.persistent_volume_type
  encrypted         = var.ebs_encryption_enabled
  
  tags = merge(
    {
      Name    = "${var.user_prefix}-${var.cluster_name}-persistent-${count.index + 1}"
      Owner   = var.owner
      Project = var.project
      Type    = "Redis-Persistent-Volume"
    },
    var.tags
  )
}

# Attach persistent volumes to Redis Enterprise nodes
resource "aws_volume_attachment" "redis_persistent_attachment" {
  count       = var.node_count
  device_name = "/dev/sdg"
  volume_id   = aws_ebs_volume.redis_persistent[count.index].id
  instance_id = var.instance_ids[count.index]
  
  depends_on = [aws_ebs_volume.redis_persistent]
}