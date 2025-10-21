# =============================================================================
# VPC OUTPUTS
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
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
# ELASTICACHE OUTPUTS
# =============================================================================

output "elasticache_primary_endpoint" {
  description = "ElastiCache primary endpoint"
  value       = module.elasticache_standalone_ksn.primary_endpoint
}

output "elasticache_port" {
  description = "ElastiCache port"
  value       = "6379"
}

output "elasticache_replication_group_id" {
  description = "ElastiCache replication group ID"
  value       = module.elasticache_standalone_ksn.replication_group_id
}

# =============================================================================
# CONNECTION INFORMATION
# =============================================================================

output "redis_connection_info" {
  description = "Redis connection information"
  value = {
    endpoint = module.elasticache_standalone_ksn.primary_endpoint
    port     = "6379"
    auth     = "none"
    ssl      = false
  }
}

output "redis_cli_command" {
  description = "Redis CLI connection command"
  value       = "redis-cli -h ${module.elasticache_standalone_ksn.primary_endpoint} -p 6379"
}