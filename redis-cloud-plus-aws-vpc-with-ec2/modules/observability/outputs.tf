# =============================================================================
# OBSERVABILITY MODULE OUTPUTS
# =============================================================================

output "prometheus_url" {
  description = "URL to access Prometheus dashboard"
  value       = "http://${var.instance_public_ip}:9090"
}

output "grafana_url" {
  description = "URL to access Grafana dashboard"
  value       = "http://${var.instance_public_ip}:3000"
}

output "grafana_credentials" {
  description = "Grafana login credentials"
  value = {
    username = "admin"
    password = "admin"
  }
  sensitive = true
}

output "dashboard_urls" {
  description = "Direct URLs to Redis Cloud dashboards"
  value = {
    database_dashboard    = "http://${var.instance_public_ip}:3000/d/oVMyPiP4k/database-status-dashboard"
    subscription_dashboard = "http://${var.instance_public_ip}:3000/d/UjCh-Ya4k/subscription-status-dashboard"
    proxy_dashboard       = "http://${var.instance_public_ip}:3000/d/edq5t67w5il1cb/proxy-threads"
  }
}

output "monitoring_info" {
  description = "Complete monitoring setup information"
  value = {
    prometheus_url = "http://${var.instance_public_ip}:9090"
    grafana_url = "http://${var.instance_public_ip}:3000"
    username = "admin"
    password = "admin"
    dashboards = [
      "Database Status Dashboard - Redis Cloud database performance metrics",
      "Subscription Status Dashboard - Redis Cloud subscription and cluster metrics", 
      "Proxy Threads Dashboard - Redis Cloud proxy performance and connection metrics"
    ]
  }
  sensitive = true
}