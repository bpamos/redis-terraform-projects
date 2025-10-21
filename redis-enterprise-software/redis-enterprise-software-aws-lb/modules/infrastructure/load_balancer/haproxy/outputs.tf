# =============================================================================
# HAPROXY LOAD BALANCER OUTPUTS
# =============================================================================

output "instance_ids" {
  description = "IDs of HAProxy instances"
  value       = aws_instance.haproxy[*].id
}

output "public_ips" {
  description = "Public IP addresses of HAProxy instances"
  value       = aws_instance.haproxy[*].public_ip
}

output "private_ips" {
  description = "Private IP addresses of HAProxy instances"
  value       = aws_instance.haproxy[*].private_ip
}

output "cluster_ui_endpoint" {
  description = "Redis Enterprise cluster UI endpoint"
  value       = "https://${aws_instance.haproxy[0].public_ip}:8443"
}

output "cluster_api_endpoint" {
  description = "Redis Enterprise cluster API endpoint"
  value       = "https://${aws_instance.haproxy[0].public_ip}:9443"
}

output "database_endpoint_base" {
  description = "Base endpoint for Redis databases (append :port)"
  value       = aws_instance.haproxy[0].public_ip
}

output "haproxy_stats_endpoints" {
  description = "HAProxy statistics endpoints"
  value       = [for ip in aws_instance.haproxy[*].public_ip : "http://${ip}:8404/stats"]
}

output "security_group_id" {
  description = "Security group ID for HAProxy instances"
  value       = aws_security_group.haproxy.id
}

output "load_balancer_endpoints" {
  description = "All HAProxy endpoints for redundancy"
  value = {
    primary = {
      ui_endpoint  = "https://${aws_instance.haproxy[0].public_ip}:8443"
      api_endpoint = "https://${aws_instance.haproxy[0].public_ip}:9443"
      db_endpoint  = aws_instance.haproxy[0].public_ip
    }
    secondary = length(aws_instance.haproxy) > 1 ? {
      ui_endpoint  = "https://${aws_instance.haproxy[1].public_ip}:8443"
      api_endpoint = "https://${aws_instance.haproxy[1].public_ip}:9443"
      db_endpoint  = aws_instance.haproxy[1].public_ip
    } : null
  }
}