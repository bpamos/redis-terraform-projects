# =============================================================================
# REDIS ENTERPRISE INSTALL MODULE OUTPUTS
# =============================================================================

output "installation_status" {
  description = "Installation status for each node"
  value = {
    for i in range(var.node_count) :
    "node-${i + 1}" => {
      instance_id = var.instance_ids[i]
      public_ip   = length(var.public_ips) > 0 ? var.public_ips[i] : null
      private_ip  = var.private_ips[i]
      installed   = null_resource.redis_enterprise_installation[i].id != null
    }
  }
}

output "installation_completion_ids" {
  description = "Installation completion resource IDs"
  value       = null_resource.redis_enterprise_installation[*].id
}