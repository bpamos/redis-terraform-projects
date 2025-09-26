# =============================================================================
# AWS NETWORK LOAD BALANCER OUTPUTS
# =============================================================================

output "dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = aws_lb.redis_enterprise.dns_name
}

output "zone_id" {
  description = "Hosted zone ID of the Network Load Balancer"
  value       = aws_lb.redis_enterprise.zone_id
}

output "cluster_ui_endpoint" {
  description = "Redis Enterprise cluster UI endpoint"
  value       = "https://${aws_lb.redis_enterprise.dns_name}:8443"
}

output "cluster_api_endpoint" {
  description = "Redis Enterprise cluster API endpoint"
  value       = "https://${aws_lb.redis_enterprise.dns_name}:9443"
}

output "database_endpoint_base" {
  description = "Base endpoint for Redis databases (append :port)"
  value       = aws_lb.redis_enterprise.dns_name
}

output "load_balancer_arn" {
  description = "ARN of the Network Load Balancer"
  value       = aws_lb.redis_enterprise.arn
}

output "target_group_arns" {
  description = "ARNs of target groups"
  value = {
    cluster_ui   = aws_lb_target_group.cluster_ui.arn
    rest_api     = aws_lb_target_group.rest_api.arn
    database_ports = aws_lb_target_group.database_ports[*].arn
  }
}

output "available_database_ports" {
  description = "List of database ports configured on the load balancer"
  value       = [for i in range(10) : 12000 + i]
}