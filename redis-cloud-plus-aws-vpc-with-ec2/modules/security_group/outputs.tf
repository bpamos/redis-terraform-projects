# =============================================================================
# SECURITY GROUP ID OUTPUTS
# =============================================================================

output "riot_ec2_sg_id" {
  description = "ID of the RIOT EC2 security group"
  value       = aws_security_group.riot_ec2.id
}

output "elasticache_sg_id" {
  description = "ID of the ElastiCache security group"
  value       = aws_security_group.elasticache.id
}

output "ec2_application_sg_id" {
  description = "ID of the application EC2 security group"
  value       = aws_security_group.ec2_application.id
}

# =============================================================================
# SECURITY GROUP ARN OUTPUTS
# =============================================================================

output "riot_ec2_sg_arn" {
  description = "ARN of the RIOT EC2 security group"
  value       = aws_security_group.riot_ec2.arn
}

output "elasticache_sg_arn" {
  description = "ARN of the ElastiCache security group"
  value       = aws_security_group.elasticache.arn
}

output "ec2_application_sg_arn" {
  description = "ARN of the application EC2 security group"
  value       = aws_security_group.ec2_application.arn
}

# =============================================================================
# ACCESS CONFIGURATION OUTPUTS
# =============================================================================

output "ssh_access_enabled" {
  description = "Whether SSH access is enabled"
  value       = var.enable_ssh_access
}

output "observability_access_enabled" {
  description = "Whether observability tools access is enabled"
  value       = var.enable_observability_access
}

output "riotx_metrics_enabled" {
  description = "Whether RIOT-X metrics access is enabled"
  value       = var.enable_riotx_metrics
}

output "redis_oss_access_enabled" {
  description = "Whether Redis OSS external access is enabled"
  value       = var.enable_redis_oss_access
}

# =============================================================================
# PORT CONFIGURATION OUTPUTS
# =============================================================================

output "application_ports" {
  description = "Summary of configured application ports"
  value = {
    flask_port      = var.enable_flask_access ? var.flask_port : null
    cutover_ui_port = var.enable_cutover_ui_access ? var.cutover_ui_port : null
    riotx_metrics_port = var.enable_riotx_metrics ? var.riotx_metrics_port : null
    custom_ports    = var.custom_application_ports
  }
}

# =============================================================================
# SECURITY CONFIGURATION SUMMARY
# =============================================================================

output "security_groups_summary" {
  description = "Summary of all created security groups and their configurations"
  value = {
    riot_ec2 = {
      id          = aws_security_group.riot_ec2.id
      name        = aws_security_group.riot_ec2.name
      description = aws_security_group.riot_ec2.description
      ssh_enabled = var.enable_ssh_access
      observability_enabled = var.enable_observability_access
      metrics_enabled = var.enable_riotx_metrics
      redis_oss_enabled = var.enable_redis_oss_access
    }
    elasticache = {
      id          = aws_security_group.elasticache.id
      name        = aws_security_group.elasticache.name
      description = aws_security_group.elasticache.description
      redis_port  = 6379
      additional_sgs_count = length(var.additional_redis_security_groups)
    }
    ec2_application = {
      id          = aws_security_group.ec2_application.id
      name        = aws_security_group.ec2_application.name
      description = aws_security_group.ec2_application.description
      ssh_enabled = var.enable_ssh_access
      flask_enabled = var.enable_flask_access
      cutover_ui_enabled = var.enable_cutover_ui_access
      custom_ports_count = length(var.custom_application_ports)
    }
  }
}