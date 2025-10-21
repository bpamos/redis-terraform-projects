# =============================================================================
# NGINX LOAD BALANCER OUTPUTS
# =============================================================================

# =============================================================================
# INSTANCE INFORMATION
# =============================================================================

output "instance_ids" {
  description = "IDs of NGINX load balancer instances"
  value       = aws_instance.nginx[*].id
}

output "public_ips" {
  description = "Public IP addresses of NGINX instances"
  value       = aws_instance.nginx[*].public_ip
}

output "private_ips" {
  description = "Private IP addresses of NGINX instances"
  value       = aws_instance.nginx[*].private_ip
}

output "security_group_id" {
  description = "Security group ID for NGINX instances"
  value       = aws_security_group.nginx.id
}

# =============================================================================
# SERVICE ENDPOINTS
# =============================================================================

output "cluster_ui_endpoint" {
  description = "Redis Enterprise cluster UI endpoint through NGINX"
  value       = "https://${aws_instance.nginx[0].public_ip}:${var.frontend_ui_port}"
}

output "cluster_api_endpoint" {
  description = "Redis Enterprise cluster API endpoint through NGINX"
  value       = "https://${aws_instance.nginx[0].public_ip}:${var.frontend_api_port}"
}

output "database_endpoint" {
  description = "Redis database endpoint through NGINX"
  value       = "${aws_instance.nginx[0].public_ip}:${var.frontend_database_port}"
}

output "database_endpoint_base" {
  description = "Base endpoint for Redis databases (append :port for additional DBs)"
  value       = aws_instance.nginx[0].public_ip
}

# =============================================================================
# HEALTH AND STATUS ENDPOINTS
# =============================================================================

output "nginx_status_endpoints" {
  description = "NGINX status page endpoints for monitoring"
  value       = [for ip in aws_instance.nginx[*].public_ip : "http://${ip}/nginx-status"]
}

output "nginx_health_endpoints" {
  description = "NGINX health check endpoints"
  value       = [for ip in aws_instance.nginx[*].public_ip : "http://${ip}/health"]
}

# =============================================================================
# LOAD BALANCER CONFIGURATION
# =============================================================================

output "load_balancer_endpoints" {
  description = "All NGINX load balancer endpoints for high availability"
  value = {
    for i, instance in aws_instance.nginx : "nginx-${i + 1}" => {
      instance_id  = instance.id
      public_ip    = instance.public_ip
      private_ip   = instance.private_ip
      ui_endpoint  = "https://${instance.public_ip}:${var.frontend_ui_port}"
      api_endpoint = "https://${instance.public_ip}:${var.frontend_api_port}"
      db_endpoint  = "${instance.public_ip}:${var.frontend_database_port}"
      status_url   = "http://${instance.public_ip}/nginx-status"
      health_url   = "http://${instance.public_ip}/health"
    }
  }
}

output "primary_endpoints" {
  description = "Primary NGINX instance endpoints"
  value = {
    instance_id       = aws_instance.nginx[0].id
    public_ip         = aws_instance.nginx[0].public_ip
    private_ip        = aws_instance.nginx[0].private_ip
    ui_endpoint       = "https://${aws_instance.nginx[0].public_ip}:${var.frontend_ui_port}"
    api_endpoint      = "https://${aws_instance.nginx[0].public_ip}:${var.frontend_api_port}"
    database_endpoint = "${aws_instance.nginx[0].public_ip}:${var.frontend_database_port}"
    status_endpoint   = "http://${aws_instance.nginx[0].public_ip}/nginx-status"
    health_endpoint   = "http://${aws_instance.nginx[0].public_ip}/health"
  }
}

# =============================================================================
# ADDITIONAL DATABASE ENDPOINTS
# =============================================================================

output "additional_database_endpoints" {
  description = "Additional database endpoints if configured"
  value = var.additional_database_ports != null ? {
    for port_config in var.additional_database_ports : port_config.name => {
      endpoint     = "${aws_instance.nginx[0].public_ip}:${port_config.frontend_port}"
      backend_port = port_config.backend_port
      name         = port_config.name
    }
  } : {}
}

# =============================================================================
# CONNECTION INFORMATION
# =============================================================================

output "connection_info" {
  description = "Redis connection information through NGINX load balancer"
  value = {
    redis_cli_command = "redis-cli -h ${aws_instance.nginx[0].public_ip} -p ${var.frontend_database_port}"
    database_host     = aws_instance.nginx[0].public_ip
    database_port     = var.frontend_database_port
    ui_url            = "https://${aws_instance.nginx[0].public_ip}:${var.frontend_ui_port}"
    api_url           = "https://${aws_instance.nginx[0].public_ip}:${var.frontend_api_port}"
  }
}

# =============================================================================
# HIGH AVAILABILITY INFORMATION
# =============================================================================

output "ha_configuration" {
  description = "High availability configuration details"
  value = {
    instance_count    = length(aws_instance.nginx)
    load_balancer_ips = aws_instance.nginx[*].public_ip
    backup_endpoints = length(aws_instance.nginx) > 1 ? {
      for i, instance in slice(aws_instance.nginx, 1, length(aws_instance.nginx)) :
      "backup-${i}" => {
        ui_endpoint  = "https://${instance.public_ip}:${var.frontend_ui_port}"
        api_endpoint = "https://${instance.public_ip}:${var.frontend_api_port}"
        db_endpoint  = "${instance.public_ip}:${var.frontend_database_port}"
      }
    } : {}
  }
}

# =============================================================================
# NGINX CONFIGURATION DETAILS
# =============================================================================

output "nginx_configuration" {
  description = "NGINX configuration summary"
  value = {
    version                 = "1.24.0 (built from source with stream module)"
    worker_processes        = var.worker_processes
    worker_connections      = var.worker_connections
    database_lb_method      = var.database_lb_method
    api_lb_method           = var.api_lb_method
    ui_lb_method            = var.ui_lb_method
    ssl_passthrough_enabled = var.enable_ssl_passthrough
    access_log_enabled      = var.enable_access_log
    stream_log_enabled      = var.enable_stream_log
  }
}