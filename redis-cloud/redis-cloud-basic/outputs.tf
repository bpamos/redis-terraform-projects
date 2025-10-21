# =============================================================================
# REDIS CLOUD OUTPUTS
# =============================================================================

output "rediscloud_subscription_id" {
  description = "Redis Cloud subscription ID"
  value       = module.rediscloud.rediscloud_subscription_id
}

output "database_id" {
  description = "Redis Cloud database ID"
  value       = module.rediscloud.database_id
}

output "database_public_endpoint" {
  description = "Redis Cloud database public endpoint"
  value       = module.rediscloud.database_public_endpoint
}

output "database_private_endpoint" {
  description = "Redis Cloud database private endpoint"
  value       = module.rediscloud.database_private_endpoint
}

output "rediscloud_password" {
  description = "Redis Cloud database password"
  value       = module.rediscloud.rediscloud_password
  sensitive   = true
}

output "redis_connection_string" {
  description = "Complete Redis connection string"
  value       = format("redis://:%s@%s", module.rediscloud.rediscloud_password, module.rediscloud.database_public_endpoint)
  sensitive   = true
}

