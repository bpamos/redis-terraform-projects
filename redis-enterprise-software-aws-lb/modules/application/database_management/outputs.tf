# =============================================================================
# DATABASE MANAGEMENT MODULE OUTPUTS
# =============================================================================

output "sample_database_info" {
  description = "Sample database information"
  value = var.create_sample_database ? {
    name    = var.sample_db_name
    port    = var.sample_db_port
    memory  = var.sample_db_memory
    created = length(null_resource.sample_database) > 0
  } : null
}

output "sample_database_endpoint" {
  description = "Sample database connection info (port only - combine with load balancer endpoint)"
  value       = var.create_sample_database ? var.sample_db_port : null
}

output "sample_database_endpoint_private" {
  description = "Sample database connection info (port only - combine with load balancer endpoint)" 
  value       = var.create_sample_database ? var.sample_db_port : null
}

output "database_creation_id" {
  description = "Database creation resource ID"
  value       = var.create_sample_database ? (length(null_resource.sample_database) > 0 ? null_resource.sample_database[0].id : null) : null
}