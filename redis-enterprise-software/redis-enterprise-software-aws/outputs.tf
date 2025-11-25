# =============================================================================
# VPC OUTPUTS
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
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

output "availability_zones" {
  description = "List of availability zones used"
  value       = slice(data.aws_availability_zones.available.names, 0, length(var.public_subnet_cidrs))
}

# =============================================================================
# REDIS ENTERPRISE CLUSTER OUTPUTS
# =============================================================================

output "redis_enterprise_cluster_nodes" {
  description = "Information about Redis Enterprise cluster nodes"
  value = {
    instance_ids = module.redis_instances.instance_ids
    public_ips   = module.redis_instances.public_ips
    private_ips  = module.redis_instances.private_ips
    public_dns   = module.redis_instances.public_dns
  }
}

output "cluster_ui_url" {
  description = "URL to access Redis Enterprise cluster UI"
  value       = module.dns.redis_ui_url != null ? module.dns.redis_ui_url : "https://${module.redis_instances.public_ips[0]}:8443"
}

output "cluster_api_url" {
  description = "URL for Redis Enterprise cluster API"
  value       = module.dns.redis_api_url != null ? module.dns.redis_api_url : "https://${module.redis_instances.public_ips[0]}:9443"
}

# =============================================================================
# DNS OUTPUTS
# =============================================================================

output "dns_records" {
  description = "DNS record information"
  value = {
    hosted_zone_name        = module.dns.hosted_zone_name
    redis_cluster_fqdn      = module.dns.redis_cluster_fqdn
    redis_cluster_ns_record = module.dns.redis_cluster_ns_record
    redis_node_glue_records = module.dns.redis_node_glue_records
  }
}

# =============================================================================
# CONNECTION INFORMATION
# =============================================================================

output "ssh_commands" {
  description = "SSH commands to connect to each cluster node"
  value = {
    for i in range(length(module.redis_instances.public_ips)) :
    "node-${i + 1}" => "ssh -i ${var.ssh_private_key_path} ${module.redis_instances.platform_config.user}@${module.redis_instances.public_ips[i]}"
  }
}

output "cluster_connection_info" {
  description = "Redis Enterprise cluster connection information"
  value = {
    cluster_fqdn = module.cluster_bootstrap.cluster_fqdn
    ui_port      = 8443
    api_port     = 9443
    username     = var.cluster_username
    password     = var.cluster_password
  }
  sensitive = true
}

# =============================================================================
# USEFUL COMMANDS
# =============================================================================

output "useful_commands" {
  description = "Useful commands for managing the Redis Enterprise cluster"
  value = {
    check_cluster_status = "ssh -i ${var.ssh_private_key_path} ${module.redis_instances.platform_config.user}@${module.redis_instances.public_ips[0]} 'sudo /opt/redislabs/bin/rladmin status'"
    view_cluster_info    = "ssh -i ${var.ssh_private_key_path} ${module.redis_instances.platform_config.user}@${module.redis_instances.public_ips[0]} 'sudo /opt/redislabs/bin/rladmin info cluster'"
    list_databases       = "ssh -i ${var.ssh_private_key_path} ${module.redis_instances.platform_config.user}@${module.redis_instances.public_ips[0]} 'sudo /opt/redislabs/bin/rladmin status databases'"
    cluster_logs         = "ssh -i ${var.ssh_private_key_path} ${module.redis_instances.platform_config.user}@${module.redis_instances.public_ips[0]} 'sudo tail -f /var/opt/redislabs/log/supervisor/*.log'"
  }
}

# =============================================================================
# CLUSTER VALIDATION OUTPUTS
# =============================================================================

output "cluster_validation_status" {
  description = "Comprehensive cluster validation status showing all nodes joined successfully"
  value       = module.cluster_bootstrap.cluster_validation_status
}

output "cluster_health_verification" {
  description = "Detailed cluster health and node verification information"
  value = {
    validation_completed  = module.cluster_bootstrap.cluster_verification != null
    expected_nodes        = var.node_count
    actual_nodes          = length(module.redis_instances.instance_ids)
    all_instances_created = length(module.redis_instances.instance_ids) == var.node_count
    cluster_fqdn          = module.cluster_bootstrap.cluster_fqdn
    validation_summary    = "✅ Cluster validation ensures all ${var.node_count} Redis Enterprise nodes joined successfully via rladmin status checks"
    verification_command  = "ssh -i ${var.ssh_private_key_path} ${module.redis_instances.platform_config.user}@${module.redis_instances.public_ips[0]} 'sudo /opt/redislabs/bin/rladmin status'"
  }
}

# =============================================================================
# DATABASE OUTPUTS
# =============================================================================

output "sample_database_info" {
  description = "Information about the sample Redis database"
  value       = module.database_management.sample_database_info
}

output "sample_database_endpoint" {
  description = "External endpoint for connecting to the sample Redis database"
  value       = module.database_management.sample_database_endpoint
}

output "sample_database_endpoint_private" {
  description = "Private endpoint for connecting to the sample Redis database from within VPC"
  value       = module.database_management.sample_database_endpoint_private
}

output "redis_connection_examples" {
  description = "Example commands for connecting to the Redis database"
  value = var.create_sample_database ? {
    redis_cli_external  = "redis-cli -h ${module.database_management.sample_database_endpoint != null ? split(":", module.database_management.sample_database_endpoint)[0] : "N/A"} -p ${var.sample_db_port}"
    redis_cli_private   = "redis-cli -h ${module.database_management.sample_database_endpoint_private != null ? split(":", module.database_management.sample_database_endpoint_private)[0] : "N/A"} -p ${var.sample_db_port}"
    redis_cli_direct_ip = "redis-cli -h ${module.redis_instances.public_ips[0]} -p ${var.sample_db_port}"
    test_external       = "redis-cli -h ${module.database_management.sample_database_endpoint != null ? split(":", module.database_management.sample_database_endpoint)[0] : "N/A"} -p ${var.sample_db_port} ping"
    test_private        = "redis-cli -h ${module.database_management.sample_database_endpoint_private != null ? split(":", module.database_management.sample_database_endpoint_private)[0] : "N/A"} -p ${var.sample_db_port} ping"
  } : null
}

# =============================================================================
# CLUSTER CREDENTIALS
# =============================================================================

output "cluster_username" {
  description = "Redis Enterprise cluster admin username"
  value       = var.cluster_username
}

output "cluster_password" {
  description = "Redis Enterprise cluster admin password"
  value       = var.cluster_password
}

output "cluster_credentials" {
  description = "Redis Enterprise cluster login credentials"
  value = {
    username = var.cluster_username
    password = var.cluster_password
    ui_url   = module.dns.redis_ui_url != null ? module.dns.redis_ui_url : "https://${module.redis_instances.public_ips[0]}:8443"
    api_url  = module.dns.redis_api_url != null ? module.dns.redis_api_url : "https://${module.redis_instances.public_ips[0]}:9443"
  }
  sensitive = true
}

# =============================================================================
# TEST NODE INFORMATION
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