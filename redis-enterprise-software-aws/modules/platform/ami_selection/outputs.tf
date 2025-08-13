# =============================================================================
# AMI SELECTION MODULE OUTPUTS
# =============================================================================

output "ami_id" {
  description = "Selected AMI ID based on platform"
  value       = local.selected_config.ami_id
}

output "ssh_user" {
  description = "SSH user for the selected platform"
  value       = local.selected_config.user
}

output "platform_info" {
  description = "Platform configuration details"
  value = {
    platform = var.platform
    ami_id   = local.selected_config.ami_id
    user     = local.selected_config.user
  }
}