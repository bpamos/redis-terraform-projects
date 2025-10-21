# =============================================================================
# OUTPUTS
# Connection information for your Redis Cloud database
# =============================================================================

output "vpc_id" {
  description = "AWS VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "AWS VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "redis_subscription_id" {
  description = "Redis Cloud subscription ID"
  value       = rediscloud_subscription.subscription.id
}

output "redis_database_id" {
  description = "Redis Cloud database ID"
  value       = rediscloud_subscription_database.database.db_id
}

output "redis_public_endpoint" {
  description = "Redis public endpoint (host:port)"
  value       = rediscloud_subscription_database.database.public_endpoint
}

output "redis_private_endpoint" {
  description = "Redis private endpoint for VPC connections (host:port)"
  value       = rediscloud_subscription_database.database.private_endpoint
}

output "redis_password" {
  description = "Redis database password"
  value       = rediscloud_subscription_database.database.password
  sensitive   = true
}

output "redis_connection_string" {
  description = "Complete Redis connection string"
  value = format("redis://default:%s@%s",
    rediscloud_subscription_database.database.password,
    rediscloud_subscription_database.database.public_endpoint
  )
  sensitive = true
}

output "redis_cli_command" {
  description = "Command to connect with redis-cli"
  value = format("redis-cli -h %s -p %s -a '%s'",
    split(":", rediscloud_subscription_database.database.private_endpoint)[0],
    split(":", rediscloud_subscription_database.database.private_endpoint)[1],
    rediscloud_subscription_database.database.password
  )
  sensitive = true
}

output "connection_info" {
  description = "All connection details"
  value = {
    public_endpoint  = rediscloud_subscription_database.database.public_endpoint
    private_endpoint = rediscloud_subscription_database.database.private_endpoint
    password         = rediscloud_subscription_database.database.password
  }
  sensitive = true
}
