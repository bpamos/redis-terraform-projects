# =============================================================================
# VPC OUTPUTS
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

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

# =============================================================================
# CONNECTION INFORMATION
# =============================================================================

output "redis_cloud_connection_info" {
  description = "Redis Cloud connection information"
  value = {
    public_endpoint  = module.rediscloud.database_public_endpoint
    private_endpoint = module.rediscloud.database_private_endpoint
    password         = module.rediscloud.rediscloud_password
  }
  sensitive = true
}

output "redis_cloud_cli_command" {
  description = "Redis CLI command to connect to Redis Cloud"
  value       = format("redis-cli -h %s -p %s -a %s", 
                      split(":", module.rediscloud.database_public_endpoint)[0],
                      split(":", module.rediscloud.database_public_endpoint)[1],
                      module.rediscloud.rediscloud_password)
  sensitive = true
}