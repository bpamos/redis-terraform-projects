# =============================================================================
# USER DATA MODULE OUTPUTS
# =============================================================================

output "user_data_base64" {
  description = "Base64 encoded user data script"
  value       = base64encode(local.user_data_rendered)
}

output "user_data_rendered" {
  description = "Rendered user data script (for debugging)"
  value       = local.user_data_rendered
}