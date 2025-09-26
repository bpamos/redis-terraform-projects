# =============================================================================
# LOAD BALANCER MODULE OUTPUTS
# =============================================================================

# Conditional outputs based on load balancer type
output "cluster_ui_endpoint" {
  description = "Redis Enterprise cluster UI endpoint"
  value = var.load_balancer_type == "nlb" ? (
    length(module.nlb_load_balancer) > 0 ? module.nlb_load_balancer[0].cluster_ui_endpoint : ""
  ) : var.load_balancer_type == "haproxy" ? (
    length(module.haproxy_load_balancer) > 0 ? module.haproxy_load_balancer[0].cluster_ui_endpoint : ""
  ) : (
    length(module.nginx_load_balancer) > 0 ? module.nginx_load_balancer[0].cluster_ui_endpoint : ""
  )
}

output "cluster_api_endpoint" {
  description = "Redis Enterprise cluster API endpoint"  
  value = var.load_balancer_type == "nlb" ? (
    length(module.nlb_load_balancer) > 0 ? module.nlb_load_balancer[0].cluster_api_endpoint : ""
  ) : var.load_balancer_type == "haproxy" ? (
    length(module.haproxy_load_balancer) > 0 ? module.haproxy_load_balancer[0].cluster_api_endpoint : ""
  ) : (
    length(module.nginx_load_balancer) > 0 ? module.nginx_load_balancer[0].cluster_api_endpoint : ""
  )
}

output "database_endpoint_base" {
  description = "Base endpoint for Redis databases (append port for specific database)"
  value = var.load_balancer_type == "nlb" ? (
    length(module.nlb_load_balancer) > 0 ? module.nlb_load_balancer[0].database_endpoint_base : ""
  ) : var.load_balancer_type == "haproxy" ? (
    length(module.haproxy_load_balancer) > 0 ? module.haproxy_load_balancer[0].database_endpoint_base : ""
  ) : (
    length(module.nginx_load_balancer) > 0 ? module.nginx_load_balancer[0].database_endpoint_base : ""
  )
}

output "load_balancer_type" {
  description = "Type of load balancer deployed"
  value       = var.load_balancer_type
}

output "load_balancer_info" {
  description = "Information about the deployed load balancer"
  value = var.load_balancer_type == "nlb" ? (
    length(module.nlb_load_balancer) > 0 ? {
      type = "AWS Network Load Balancer"
      management = "AWS managed service"
      dns_name = module.nlb_load_balancer[0].dns_name
      instance_ids = null
      version = "AWS managed"
    } : {
      type = null
      management = null
      dns_name = null
      instance_ids = null
      version = null
    }
  ) : var.load_balancer_type == "haproxy" ? (
    length(module.haproxy_load_balancer) > 0 ? {
      type = "HAProxy on EC2"
      management = "Self-managed"
      dns_name = module.haproxy_load_balancer[0].public_ips[0]
      instance_ids = module.haproxy_load_balancer[0].instance_ids
      version = "HAProxy package version"
    } : {
      type = null
      management = null
      dns_name = null
      instance_ids = null
      version = null
    }
  ) : (
    length(module.nginx_load_balancer) > 0 ? {
      type = "NGINX on EC2"
      management = "Self-managed"
      dns_name = module.nginx_load_balancer[0].public_ips[0]
      instance_ids = module.nginx_load_balancer[0].instance_ids
      version = "NGINX 1.24.0 with stream module"
    } : {
      type = null
      management = null
      dns_name = null
      instance_ids = null
      version = null
    }
  )
}