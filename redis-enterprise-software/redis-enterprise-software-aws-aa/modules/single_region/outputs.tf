# =============================================================================
# SINGLE REGION MODULE OUTPUTS
# =============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = var.region_config.vpc_cidr
}

output "private_route_table_id" {
  description = "Private route table ID"
  value       = module.vpc.private_route_table_ids[0]
}

output "public_route_table_id" {
  description = "Public route table ID"
  value       = module.vpc.public_route_table_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "redis_enterprise_sg_id" {
  description = "Redis Enterprise security group ID"
  value       = module.security_group.redis_enterprise_sg_id
}

output "instance_ids" {
  description = "Redis Enterprise instance IDs"
  value       = module.redis_instances.instance_ids
}

output "private_ips" {
  description = "Redis Enterprise node private IPs"
  value       = module.redis_instances.private_ips
}

output "public_ips" {
  description = "Redis Enterprise node public IPs (EIPs or regular public IPs)"
  value       = module.redis_instances.public_ips
}

output "availability_zones" {
  description = "Availability zones for Redis Enterprise nodes"
  value       = module.redis_instances.availability_zones
}

output "cluster_fqdn" {
  description = "Cluster FQDN"
  value       = "${local.cluster_fqdn}.${var.hosted_zone_name}"
}

output "cluster_ui_url" {
  description = "Cluster UI URL"
  value       = "https://${local.cluster_fqdn}.${var.hosted_zone_name}:8443"
}

output "cluster_api_url" {
  description = "Cluster API URL"
  value       = "https://${local.cluster_fqdn}.${var.hosted_zone_name}:9443"
}

output "region" {
  description = "AWS region"
  value       = var.region
}

# =============================================================================
# TEST NODE OUTPUT
# =============================================================================

output "test_node_info" {
  description = "Test node information"
  value = var.enable_test_node ? {
    instance_id = module.test_node[0].instance_id
    public_ip   = module.test_node[0].public_ip
    private_ip  = module.test_node[0].private_ip
    ssh_command = module.test_node[0].ssh_command
  } : null
}
