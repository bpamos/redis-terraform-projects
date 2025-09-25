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
# REDIS CLOUD SUBSCRIPTION OUTPUTS
# =============================================================================

output "subscription_id" {
  description = "Redis Cloud subscription ID"
  value       = module.redis_subscription.subscription_id
}

output "subscription_name" {
  description = "Redis Cloud subscription name"
  value       = module.redis_subscription.subscription_name
}

output "subscription_region" {
  description = "Redis Cloud subscription region"
  value       = module.redis_subscription.subscription_region
}

output "subscription_cidr" {
  description = "CIDR block of the subscription VPC"
  value       = module.redis_subscription.subscription_cidr
}

# =============================================================================
# PRIMARY DATABASE OUTPUTS
# =============================================================================

output "database_id" {
  description = "Primary Redis Cloud database ID"
  value       = module.redis_database_primary.database_id
}

output "database_name" {
  description = "Primary Redis Cloud database name"
  value       = module.redis_database_primary.database_name
}

output "database_endpoint" {
  description = "Primary Redis Cloud database public endpoint"
  value       = module.redis_database_primary.database_endpoint
  sensitive   = false
}

output "database_private_endpoint" {
  description = "Primary Redis Cloud database private endpoint"
  value       = module.redis_database_primary.database_private_endpoint
  sensitive   = false
}

output "database_password" {
  description = "Primary Redis Cloud database password"
  value       = module.redis_database_primary.database_password
  sensitive   = true
}

output "connection_string" {
  description = "Primary Redis database connection string"
  value       = module.redis_database_primary.database_connection_string
  sensitive   = true
}

# Legacy outputs for backward compatibility
output "rediscloud_subscription_id" {
  description = "Redis Cloud subscription ID (legacy)"
  value       = module.redis_subscription.subscription_id
}

output "rediscloud_password" {
  description = "Redis Cloud database password (legacy)"
  value       = module.redis_database_primary.database_password
  sensitive   = true
}

output "database_public_endpoint" {
  description = "Redis Cloud database public endpoint (legacy)"
  value       = module.redis_database_primary.database_endpoint
}

# =============================================================================
# CONNECTION INFORMATION
# =============================================================================

output "redis_cloud_connection_info" {
  description = "Redis Cloud connection information"
  value = {
    public_endpoint  = module.redis_database_primary.database_endpoint
    private_endpoint = module.redis_database_primary.database_private_endpoint
    password         = module.redis_database_primary.database_password
  }
  sensitive = true
}

output "redis_cloud_cli_command" {
  description = "Redis CLI command to connect to Redis Cloud"
  value = format("redis-cli -h %s -p %s -a %s",
    split(":", module.redis_database_primary.database_endpoint)[0],
    split(":", module.redis_database_primary.database_endpoint)[1],
  module.redis_database_primary.database_password)
  sensitive = true
}

# =============================================================================
# PARSED CONNECTION DETAILS
# =============================================================================

output "database_host" {
  description = "Redis Cloud database host (public endpoint)"
  value       = split(":", module.redis_database_primary.database_endpoint)[0]
}

output "database_port" {
  description = "Redis Cloud database port (public endpoint)"
  value       = split(":", module.redis_database_primary.database_endpoint)[1]
}

output "database_private_host" {
  description = "Redis Cloud database host (private endpoint)"
  value       = split(":", module.redis_database_primary.database_private_endpoint)[0]
}

output "database_private_port" {
  description = "Redis Cloud database port (private endpoint)"
  value       = split(":", module.redis_database_primary.database_private_endpoint)[1]
}

# =============================================================================
# OBSERVABILITY OUTPUTS
# =============================================================================

output "prometheus_url" {
  description = "Prometheus dashboard URL (if observability enabled)"
  value       = var.enable_observability && var.enable_ec2_testing ? module.observability[0].prometheus_url : null
}

output "grafana_url" {
  description = "Grafana dashboard URL (if observability enabled)"
  value       = var.enable_observability && var.enable_ec2_testing ? module.observability[0].grafana_url : null
}

output "grafana_credentials" {
  description = "Grafana login credentials (if observability enabled)"
  value       = var.enable_observability && var.enable_ec2_testing ? module.observability[0].grafana_credentials : null
  sensitive   = true
}

output "monitoring_info" {
  description = "Complete Redis Cloud monitoring setup information (if observability enabled)"
  value       = var.enable_observability && var.enable_ec2_testing ? module.observability[0].monitoring_info : null
  sensitive   = true
}

output "dashboard_urls" {
  description = "Direct URLs to Redis Cloud dashboards (if observability enabled)"
  value       = var.enable_observability && var.enable_ec2_testing ? module.observability[0].dashboard_urls : null
}