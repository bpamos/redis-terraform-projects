# =============================================================================
# REDIS DATABASE OUTPUTS
# =============================================================================

output "database_id" {
  description = "Redis Cloud database ID"
  value       = rediscloud_subscription_database.db.db_id
}

output "database_name" {
  description = "Redis Cloud database name"
  value       = rediscloud_subscription_database.db.name
}

output "database_endpoint" {
  description = "Redis Cloud database public endpoint"
  value       = rediscloud_subscription_database.db.public_endpoint
}

output "database_private_endpoint" {
  description = "Redis Cloud database private endpoint"
  value       = rediscloud_subscription_database.db.private_endpoint
}

output "database_password" {
  description = "Redis Cloud database password"
  value       = rediscloud_subscription_database.db.password
  sensitive   = true
}

output "database_connection_string" {
  description = "Redis database connection string"
  value = format("redis://:%s@%s",
    rediscloud_subscription_database.db.password,
  rediscloud_subscription_database.db.private_endpoint)
  sensitive = true
}

output "database_config" {
  description = "Database configuration summary"
  value = {
    name                         = rediscloud_subscription_database.db.name
    dataset_size_in_gb           = rediscloud_subscription_database.db.dataset_size_in_gb
    memory_limit_in_gb           = rediscloud_subscription_database.db.memory_limit_in_gb
    throughput_measurement_by    = rediscloud_subscription_database.db.throughput_measurement_by
    throughput_measurement_value = rediscloud_subscription_database.db.throughput_measurement_value
    data_persistence             = rediscloud_subscription_database.db.data_persistence
    replication                  = rediscloud_subscription_database.db.replication
    modules                      = [for mod in rediscloud_subscription_database.db.modules : mod.name]
  }
}