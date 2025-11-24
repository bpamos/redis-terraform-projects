# =============================================================================
# REDIS ENTERPRISE ACTIVE-ACTIVE MULTI-REGION OUTPUTS
# =============================================================================

# =============================================================================
# DEPLOYMENT SUMMARY
# =============================================================================

output "deployment_summary" {
  description = "High-level summary of the Active-Active deployment"
  value = {
    regions_deployed    = local.region_list
    total_clusters      = length(local.region_list)
    nodes_per_region    = var.node_count_per_region
    total_nodes         = length(local.region_list) * var.node_count_per_region
    crdb_created        = var.create_crdb_database && length(local.region_list) > 1
    crdb_name           = var.create_crdb_database && length(local.region_list) > 1 ? var.crdb_database_name : null
    deployment_type     = "Active-Active Multi-Region"
  }
}

# =============================================================================
# CLUSTER INFORMATION PER REGION
# =============================================================================

output "clusters" {
  description = "Redis Enterprise cluster information for each region"
  value = merge(
    {
      (local.region_list[0]) = {
        region           = local.region_list[0]
        vpc_id           = module.redis_cluster_region1.vpc_id
        cluster_fqdn     = module.redis_cluster_region1.cluster_fqdn
        cluster_ui_url   = module.redis_cluster_region1.cluster_ui_url
        cluster_api_url  = module.redis_cluster_region1.cluster_api_url
        private_ips      = module.redis_cluster_region1.private_ips
        instance_ids     = module.redis_cluster_region1.instance_ids
      }
    },
    length(local.region_list) > 1 ? {
      (local.region_list[1]) = {
        region           = local.region_list[1]
        vpc_id           = module.redis_cluster_region2[0].vpc_id
        cluster_fqdn     = module.redis_cluster_region2[0].cluster_fqdn
        cluster_ui_url   = module.redis_cluster_region2[0].cluster_ui_url
        cluster_api_url  = module.redis_cluster_region2[0].cluster_api_url
        private_ips      = module.redis_cluster_region2[0].private_ips
        instance_ids     = module.redis_cluster_region2[0].instance_ids
      }
    } : {}
  )
}

# =============================================================================
# VPC PEERING INFORMATION
# =============================================================================

output "vpc_peering" {
  description = "VPC peering mesh information"
  value = length(local.region_list) > 1 ? {
    region_pairs            = module.vpc_peering_mesh[0].region_pairs
    peering_connection_ids  = module.vpc_peering_mesh[0].peering_connection_ids
    peering_status          = module.vpc_peering_mesh[0].peering_connection_status
  } : null
}

# =============================================================================
# ACTIVE-ACTIVE (CRDB) DATABASE INFORMATION
# =============================================================================

output "crdb_database" {
  description = "Active-Active CRDB database information"
  value = var.create_crdb_database && length(local.region_list) > 1 ? {
    name                = module.crdb[0].crdb_name
    port                = module.crdb[0].crdb_port
    memory_size_bytes   = module.crdb[0].crdb_memory_size
    participating_regions = module.crdb[0].participating_regions
    endpoints           = module.crdb[0].crdb_endpoints
    primary_cluster_url = module.crdb[0].primary_cluster_url
  } : null
}

# =============================================================================
# CONNECTION INFORMATION
# =============================================================================

output "connection_info" {
  description = "Connection information for the Active-Active deployment"
  value = {
    cluster_management = merge(
      {
        (local.region_list[0]) = {
          ui_url  = module.redis_cluster_region1.cluster_ui_url
          api_url = module.redis_cluster_region1.cluster_api_url
          fqdn    = module.redis_cluster_region1.cluster_fqdn
        }
      },
      length(local.region_list) > 1 ? {
        (local.region_list[1]) = {
          ui_url  = module.redis_cluster_region2[0].cluster_ui_url
          api_url = module.redis_cluster_region2[0].cluster_api_url
          fqdn    = module.redis_cluster_region2[0].cluster_fqdn
        }
      } : {}
    )
    crdb_endpoints = var.create_crdb_database && length(local.region_list) > 1 ? module.crdb[0].crdb_endpoints : null
    credentials = {
      username = var.cluster_username
      # password is sensitive and not shown
    }
  }
}

# =============================================================================
# QUICK ACCESS COMMANDS
# =============================================================================

output "quick_access_commands" {
  description = "Useful commands for accessing and managing the deployment"
  value = {
    verify_crdb = var.create_crdb_database && length(local.region_list) > 1 ? merge(
      {
        (local.region_list[0]) = "curl -k -u '${var.cluster_username}:PASSWORD' https://${local.region_list[0]}.${var.user_prefix}-${var.cluster_name}.${data.aws_route53_zone.main.name}:9443/v1/crdbs | jq"
      },
      length(local.region_list) > 1 ? {
        (local.region_list[1]) = "curl -k -u '${var.cluster_username}:PASSWORD' https://${local.region_list[1]}.${var.user_prefix}-${var.cluster_name}.${data.aws_route53_zone.main.name}:9443/v1/crdbs | jq"
      } : {}
    ) : null
    
    connect_redis_cli = var.create_crdb_database && length(local.region_list) > 1 ? merge(
      {
        (local.region_list[0]) = "redis-cli -h redis-${var.crdb_port}.${local.region_list[0]}.${var.user_prefix}-${var.cluster_name}.${data.aws_route53_zone.main.name} -p ${var.crdb_port}"
      },
      length(local.region_list) > 1 ? {
        (local.region_list[1]) = "redis-cli -h redis-${var.crdb_port}.${local.region_list[1]}.${var.user_prefix}-${var.cluster_name}.${data.aws_route53_zone.main.name} -p ${var.crdb_port}"
      } : {}
    ) : null
    
    test_connectivity = merge(
      {
        (local.region_list[0]) = "telnet ${local.region_list[0]}.${var.user_prefix}-${var.cluster_name}.${data.aws_route53_zone.main.name} 9443"
      },
      length(local.region_list) > 1 ? {
        (local.region_list[1]) = "telnet ${local.region_list[1]}.${var.user_prefix}-${var.cluster_name}.${data.aws_route53_zone.main.name} 9443"
      } : {}
    )
  }
}

# =============================================================================
# NETWORK INFORMATION
# =============================================================================

output "network_info" {
  description = "Network configuration for all regions"
  value = merge(
    {
      (local.region_list[0]) = {
        vpc_id      = module.redis_cluster_region1.vpc_id
        vpc_cidr    = var.regions[local.region_list[0]].vpc_cidr
        private_ips = module.redis_cluster_region1.private_ips
      }
    },
    length(local.region_list) > 1 ? {
      (local.region_list[1]) = {
        vpc_id      = module.redis_cluster_region2[0].vpc_id
        vpc_cidr    = var.regions[local.region_list[1]].vpc_cidr
        private_ips = module.redis_cluster_region2[0].private_ips
      }
    } : {}
  )
}

# =============================================================================
# DNS INFORMATION
# =============================================================================

output "dns_info" {
  description = "DNS configuration for the Active-Active deployment"
  value = {
    hosted_zone_id   = var.dns_hosted_zone_id
    hosted_zone_name = data.aws_route53_zone.main.name
    cluster_fqdns    = merge(
      {
        (local.region_list[0]) = module.redis_cluster_region1.cluster_fqdn
      },
      length(local.region_list) > 1 ? {
        (local.region_list[1]) = module.redis_cluster_region2[0].cluster_fqdn
      } : {}
    )
  }
}

# =============================================================================
# TEST NODE INFORMATION
# =============================================================================

output "test_nodes" {
  description = "Test node information for each region"
  value = merge(
    {
      (local.region_list[0]) = module.redis_cluster_region1.test_node_info
    },
    length(local.region_list) > 1 ? {
      (local.region_list[1]) = module.redis_cluster_region2[0].test_node_info
    } : {}
  )
}
