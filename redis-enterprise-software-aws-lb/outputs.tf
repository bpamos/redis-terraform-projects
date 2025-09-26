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
    instance_ids  = module.redis_instances.instance_ids
    public_ips    = module.redis_instances.public_ips
    private_ips   = module.redis_instances.private_ips
    public_dns    = module.redis_instances.public_dns
  }
}

output "cluster_ui_url" {
  description = "URL to access Redis Enterprise cluster UI via load balancer"
  value       = module.load_balancer.cluster_ui_endpoint
}

output "cluster_api_url" {
  description = "URL for Redis Enterprise cluster API via load balancer"
  value       = module.load_balancer.cluster_api_endpoint
}

# =============================================================================
# LOAD BALANCER OUTPUTS
# =============================================================================

output "load_balancer_info" {
  description = "Load balancer deployment information"
  value = {
    type              = module.load_balancer.load_balancer_type
    ui_endpoint       = module.load_balancer.cluster_ui_endpoint
    api_endpoint      = module.load_balancer.cluster_api_endpoint
    database_endpoint = module.load_balancer.database_endpoint_base
    details           = module.load_balancer.load_balancer_info
  }
}

# =============================================================================
# CONNECTION INFORMATION
# =============================================================================

output "ssh_commands" {
  description = "SSH commands to connect to each cluster node"
  value = {
    for i in range(length(module.redis_instances.public_ips)) :
    "node-${i + 1}" => "ssh -i ${var.ssh_private_key_path} ${module.ami_selection.ssh_user}@${module.redis_instances.public_ips[i]}"
  }
}

output "cluster_connection_info" {
  description = "Redis Enterprise cluster connection information"
  value = {
    cluster_fqdn = module.cluster_bootstrap.cluster_fqdn
    ui_port     = 8443
    api_port    = 9443
    username    = var.cluster_username
    password    = var.cluster_password
  }
  sensitive = true
}

# =============================================================================
# USEFUL COMMANDS
# =============================================================================

output "useful_commands" {
  description = "Useful commands for managing the Redis Enterprise cluster"
  value = {
    check_cluster_status = "ssh -i ${var.ssh_private_key_path} ${module.ami_selection.ssh_user}@${module.redis_instances.public_ips[0]} 'sudo /opt/redislabs/bin/rladmin status'"
    view_cluster_info    = "ssh -i ${var.ssh_private_key_path} ${module.ami_selection.ssh_user}@${module.redis_instances.public_ips[0]} 'sudo /opt/redislabs/bin/rladmin info cluster'"
    list_databases       = "ssh -i ${var.ssh_private_key_path} ${module.ami_selection.ssh_user}@${module.redis_instances.public_ips[0]} 'sudo /opt/redislabs/bin/rladmin status databases'"
    cluster_logs         = "ssh -i ${var.ssh_private_key_path} ${module.ami_selection.ssh_user}@${module.redis_instances.public_ips[0]} 'sudo tail -f /var/opt/redislabs/log/supervisor/*.log'"
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
  description = "Load balancer endpoint for connecting to the sample Redis database"
  value       = var.create_sample_database ? "${module.load_balancer.database_endpoint_base}:${var.sample_db_port}" : null
}

output "sample_database_endpoint_private" {
  description = "Load balancer endpoint for connecting to the sample Redis database (same as external with load balancer)"
  value       = var.create_sample_database ? "${module.load_balancer.database_endpoint_base}:${var.sample_db_port}" : null
}

output "redis_connection_examples" {
  description = "Example commands for connecting to the Redis database"
  value = var.create_sample_database ? {
    redis_cli_via_lb    = "redis-cli -h ${module.load_balancer.database_endpoint_base} -p ${var.sample_db_port}"
    redis_cli_direct_ip = "redis-cli -h ${module.redis_instances.public_ips[0]} -p ${var.sample_db_port}"
    test_via_lb         = "redis-cli -h ${module.load_balancer.database_endpoint_base} -p ${var.sample_db_port} ping"
    test_direct_ip      = "redis-cli -h ${module.redis_instances.public_ips[0]} -p ${var.sample_db_port} ping"
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
    ui_url   = module.load_balancer.cluster_ui_endpoint
    api_url  = module.load_balancer.cluster_api_endpoint
  }
  sensitive = true
}