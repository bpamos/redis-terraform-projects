# =============================================================================
# CRDB MANAGEMENT MODULE OUTPUTS
# =============================================================================

output "crdb_name" {
  description = "Name of the created CRDB database"
  value       = var.crdb_name
}

output "crdb_port" {
  description = "Port of the CRDB database"
  value       = var.crdb_port
}

output "crdb_memory_size" {
  description = "Memory size of the CRDB database in bytes"
  value       = var.crdb_memory_size
}

output "primary_cluster_url" {
  description = "Primary cluster URL used for CRDB creation"
  value       = local.primary_cluster_url
}

output "participating_regions" {
  description = "List of regions participating in the CRDB"
  value       = keys(var.participating_clusters)
}

output "crdb_endpoints" {
  description = "CRDB database endpoints for each region"
  value = {
    for region, config in var.participating_clusters :
    region => "redis-${var.crdb_port}.${config.cluster_fqdn}:${var.crdb_port}"
  }
}

output "crdb_connection_info" {
  description = "Connection information for the CRDB database"
  value = {
    database_name = var.crdb_name
    port         = var.crdb_port
    replication  = var.enable_replication
    sharding     = var.enable_sharding
    endpoints    = {
      for region, config in var.participating_clusters :
      region => "redis-${var.crdb_port}.${config.cluster_fqdn}:${var.crdb_port}"
    }
  }
}
