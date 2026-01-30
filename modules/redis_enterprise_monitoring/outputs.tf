# =============================================================================
# REDIS ENTERPRISE MONITORING MODULE - OUTPUTS
# =============================================================================

# =============================================================================
# ENDPOINT URLS
# =============================================================================

output "grafana_url" {
  description = "URL to access Grafana web UI"
  value       = "http://${var.bastion_public_ip}:${var.grafana_port}"
}

output "prometheus_url" {
  description = "URL to access Prometheus web UI"
  value       = "http://${var.bastion_public_ip}:${var.prometheus_port}"
}

output "grafana_url_private" {
  description = "Private URL to access Grafana (from within VPC)"
  value       = "http://${var.bastion_private_ip}:${var.grafana_port}"
}

output "prometheus_url_private" {
  description = "Private URL to access Prometheus (from within VPC)"
  value       = "http://${var.bastion_private_ip}:${var.prometheus_port}"
}

# =============================================================================
# CREDENTIALS
# =============================================================================

output "grafana_admin_user" {
  description = "Grafana admin username"
  value       = var.grafana_admin_user
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = local.grafana_password
  sensitive   = true
}

output "grafana_credentials" {
  description = "Grafana login credentials"
  value = {
    username         = var.grafana_admin_user
    password         = local.grafana_password
    anonymous_access = var.grafana_anonymous_access
  }
  sensitive = true
}

# =============================================================================
# CONFIGURATION DETAILS
# =============================================================================

output "prometheus_config" {
  description = "Prometheus configuration details"
  value = {
    config_file     = "/etc/prometheus/prometheus.yml"
    data_dir        = "/var/lib/prometheus"
    retention_days  = var.prometheus_retention_days
    scrape_interval = var.prometheus_scrape_interval
    port            = var.prometheus_port
  }
}

output "grafana_config" {
  description = "Grafana configuration details"
  value = {
    config_file    = "/etc/grafana/grafana.ini"
    dashboards_dir = "/var/lib/grafana/dashboards/redis-enterprise"
    port           = var.grafana_port
  }
}

# =============================================================================
# REDIS ENTERPRISE SCRAPE TARGET
# =============================================================================

output "redis_metrics_endpoint" {
  description = "Redis Enterprise metrics endpoint being scraped"
  value       = "https://${var.redis_cluster_fqdn}:${var.redis_metrics_port}${local.metrics_path}"
}

output "redis_scrape_targets" {
  description = "All Redis Enterprise scrape targets"
  value = concat(
    ["${var.redis_cluster_fqdn}:${var.redis_metrics_port}"],
    [for ip in var.redis_cluster_nodes : "${ip}:${var.redis_metrics_port}"]
  )
}

# =============================================================================
# DASHBOARD INFORMATION
# =============================================================================

output "installed_dashboards" {
  description = "List of installed Grafana dashboards"
  value = var.install_ops_dashboards ? [
    "Cluster Dashboard - Overview of Redis Enterprise cluster health",
    "Database Dashboard - Per-database metrics and performance",
    "Node Dashboard - Individual node metrics",
    "Shard Dashboard - Redis shard-level metrics",
    "Latency Dashboard - Request latency analysis",
    "QPS Dashboard - Queries per second metrics",
    "Active-Active Dashboard - CRDB replication metrics"
  ] : []
}

# =============================================================================
# QUICK ACCESS COMMANDS
# =============================================================================

output "useful_commands" {
  description = "Useful commands for managing the monitoring stack"
  value = {
    check_status       = "ssh -i <key> ubuntu@${var.bastion_public_ip} './monitoring-status.sh'"
    prometheus_targets = "ssh -i <key> ubuntu@${var.bastion_public_ip} './check-prometheus-targets.sh'"
    reload_prometheus  = "ssh -i <key> ubuntu@${var.bastion_public_ip} './reload-prometheus.sh'"
    prometheus_logs    = "ssh -i <key> ubuntu@${var.bastion_public_ip} 'journalctl -u prometheus -f'"
    grafana_logs       = "ssh -i <key> ubuntu@${var.bastion_public_ip} 'journalctl -u grafana-server -f'"
  }
}

# =============================================================================
# SECURITY GROUP
# =============================================================================

output "monitoring_security_group_id" {
  description = "Security group ID used for monitoring"
  value       = var.bastion_security_group_id
}
