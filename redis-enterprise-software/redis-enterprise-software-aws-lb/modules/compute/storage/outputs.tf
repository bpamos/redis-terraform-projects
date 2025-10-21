# =============================================================================
# STORAGE MODULE OUTPUTS
# =============================================================================

output "data_volume_ids" {
  description = "List of data volume IDs"
  value       = aws_ebs_volume.redis_data[*].id
}

output "persistent_volume_ids" {
  description = "List of persistent volume IDs"
  value       = aws_ebs_volume.redis_persistent[*].id
}

output "data_volume_attachment_ids" {
  description = "List of data volume attachment IDs"
  value       = aws_volume_attachment.redis_data_attachment[*].id
}

output "persistent_volume_attachment_ids" {
  description = "List of persistent volume attachment IDs"
  value       = aws_volume_attachment.redis_persistent_attachment[*].id
}

output "volume_info" {
  description = "Comprehensive volume information"
  value = {
    data_volumes = {
      for i, volume in aws_ebs_volume.redis_data :
      "node-${i + 1}" => {
        id                = volume.id
        size              = volume.size
        type              = volume.type
        availability_zone = volume.availability_zone
        encrypted         = volume.encrypted
      }
    }
    persistent_volumes = {
      for i, volume in aws_ebs_volume.redis_persistent :
      "node-${i + 1}" => {
        id                = volume.id
        size              = volume.size
        type              = volume.type
        availability_zone = volume.availability_zone
        encrypted         = volume.encrypted
      }
    }
  }
}