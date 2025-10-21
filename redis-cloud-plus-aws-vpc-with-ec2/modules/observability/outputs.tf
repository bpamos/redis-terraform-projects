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
  sensitive = false
}

output "dashboard_urls" {
  description = "Direct URLs to Redis Cloud operational dashboards"
  value = {
    grafana_home = "http://${var.instance_public_ip}:3000"
    note = "Access all imported Redis Cloud operational dashboards from the Grafana home page"
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
      "Active-Active Dashboard - Redis Cloud Active-Active replication metrics",
      "Cluster Dashboard - Redis Cloud cluster-level performance and health metrics",
      "Database Dashboard - Redis Cloud database performance and operations metrics",
      "Latency Dashboard - Redis Cloud latency and response time metrics",
      "Node Dashboard - Redis Cloud node-level resource and performance metrics",
      "QPS Dashboard - Redis Cloud queries per second and throughput metrics",
      "Shard Dashboard - Redis Cloud shard-level performance and distribution metrics"
    ]
    source = "Official Redis Field Engineering operational dashboards"
    documentation = "https://github.com/redis-field-engineering/redis-enterprise-observability"
  }
  sensitive = true
}