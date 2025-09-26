# =============================================================================
# CLUSTER BOOTSTRAP MODULE OUTPUTS
# =============================================================================

output "cluster_fqdn" {
  description = "Full FQDN of the Redis Enterprise cluster"
  value       = var.cluster_fqdn
}

output "cluster_created" {
  description = "Cluster creation resource ID"
  value       = null_resource.create_cluster.id
}

output "nodes_joined" {
  description = "Node joining resource IDs"
  value       = null_resource.join_cluster[*].id
}

output "cluster_verification" {
  description = "Cluster verification resource ID"
  value       = null_resource.cluster_verification.id
}

output "load_balancer_config" {
  description = "Load balancer configuration resource ID"
  value       = null_resource.load_balancer_config.id
}

output "cluster_info" {
  description = "Redis Enterprise cluster information"
  value = {
    fqdn           = var.cluster_fqdn
    node_count     = var.node_count
    rack_awareness = var.rack_awareness
    flash_enabled  = var.flash_enabled
    primary_node   = {
      instance_id = var.instance_ids[0]
      public_ip   = var.public_ips[0]
      private_ip  = var.private_ips[0]
    }
    replica_nodes = [
      for i in range(1, var.node_count) : {
        instance_id = var.instance_ids[i]
        public_ip   = var.public_ips[i]
        private_ip  = var.private_ips[i]
        node_number = i + 1
      }
    ]
  }
}