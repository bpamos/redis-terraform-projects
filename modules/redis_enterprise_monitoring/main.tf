# =============================================================================
# REDIS ENTERPRISE MONITORING MODULE
# =============================================================================
# Installs Prometheus + Grafana on bastion host for Redis Enterprise monitoring
# Uses V2 metrics endpoint and ops dashboards from redis-enterprise-observability
# =============================================================================

locals {
  # Generate random Grafana password if not provided
  grafana_password = var.grafana_admin_password != "" ? var.grafana_admin_password : random_password.grafana[0].result

  # Metrics path based on version
  metrics_path = var.metrics_endpoint_version == "v2" ? "/v2" : "/"

  # Dashboard list to download
  ops_dashboards = [
    "cluster.json",
    "database.json",
    "node.json",
    "shard.json",
    "latency.json",
    "qps.json",
    "active-active.json"
  ]

  # Common tags
  common_tags = merge(
    {
      Name      = "${var.name_prefix}-monitoring"
      Owner     = var.owner
      Project   = var.project
      ManagedBy = "terraform"
      Role      = "redis-enterprise-monitoring"
    },
    var.tags
  )
}

# =============================================================================
# RANDOM PASSWORD FOR GRAFANA (if not provided)
# =============================================================================

resource "random_password" "grafana" {
  count   = var.grafana_admin_password == "" ? 1 : 0
  length  = 16
  special = true
}

# =============================================================================
# SECURITY GROUP RULES (add to existing bastion SG)
# =============================================================================

resource "aws_security_group_rule" "grafana" {
  count = var.add_security_group_rules ? 1 : 0

  type              = "ingress"
  from_port         = var.grafana_port
  to_port           = var.grafana_port
  protocol          = "tcp"
  cidr_blocks       = var.grafana_allowed_cidrs
  security_group_id = var.bastion_security_group_id
  description       = "Grafana web UI for Redis Enterprise monitoring"
}

resource "aws_security_group_rule" "prometheus" {
  count = var.add_security_group_rules ? 1 : 0

  type              = "ingress"
  from_port         = var.prometheus_port
  to_port           = var.prometheus_port
  protocol          = "tcp"
  cidr_blocks       = var.grafana_allowed_cidrs
  security_group_id = var.bastion_security_group_id
  description       = "Prometheus web UI for Redis Enterprise monitoring"
}

# =============================================================================
# PROMETHEUS CONFIGURATION FILE
# =============================================================================

resource "local_file" "prometheus_config" {
  filename = "${path.module}/generated/prometheus.yml"
  content = templatefile("${path.module}/scripts/prometheus.yml.tpl", {
    cluster_fqdn    = var.redis_cluster_fqdn
    cluster_nodes   = var.redis_cluster_nodes
    metrics_port    = var.redis_metrics_port
    metrics_path    = local.metrics_path
    scrape_interval = var.prometheus_scrape_interval
  })

  file_permission = "0644"
}

# =============================================================================
# GRAFANA DATASOURCE PROVISIONING
# =============================================================================

resource "local_file" "grafana_datasource" {
  filename = "${path.module}/generated/datasource.yml"
  content  = <<-EOT
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:${var.prometheus_port}
    isDefault: true
    editable: false
    uid: prometheus
EOT

  file_permission = "0644"
}

# =============================================================================
# GRAFANA DASHBOARD PROVISIONING CONFIG
# =============================================================================

resource "local_file" "grafana_dashboard_provider" {
  filename = "${path.module}/generated/dashboard-provider.yml"
  content  = <<-EOT
apiVersion: 1

providers:
  - name: 'Redis Enterprise'
    orgId: 1
    folder: 'Redis Enterprise Ops'
    folderUid: 'redis-enterprise-ops'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards/redis-enterprise
EOT

  file_permission = "0644"
}

# =============================================================================
# INSTALL MONITORING STACK ON BASTION
# =============================================================================

resource "null_resource" "install_monitoring" {
  depends_on = [
    local_file.prometheus_config,
    local_file.grafana_datasource,
    local_file.grafana_dashboard_provider
  ]

  triggers = {
    # Re-run if cluster FQDN changes
    cluster_fqdn = var.redis_cluster_fqdn
    # Re-run if nodes change
    cluster_nodes = join(",", var.redis_cluster_nodes)
    # Re-run if config changes
    prometheus_config = local_file.prometheus_config.content
  }

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_path)
    host        = var.bastion_public_ip
    timeout     = "5m"
  }

  # Copy Prometheus config
  provisioner "file" {
    source      = local_file.prometheus_config.filename
    destination = "/tmp/prometheus.yml"
  }

  # Copy Grafana datasource config
  provisioner "file" {
    source      = local_file.grafana_datasource.filename
    destination = "/tmp/grafana-datasource.yml"
  }

  # Copy Grafana dashboard provider config
  provisioner "file" {
    source      = local_file.grafana_dashboard_provider.filename
    destination = "/tmp/grafana-dashboard-provider.yml"
  }

  # Copy and run installation script
  provisioner "file" {
    source      = "${path.module}/scripts/install_monitoring.sh"
    destination = "/tmp/install_monitoring.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_monitoring.sh",
      "sudo /tmp/install_monitoring.sh '${var.grafana_admin_user}' '${local.grafana_password}' '${var.grafana_anonymous_access}' '${var.grafana_port}' '${var.prometheus_port}' '${var.prometheus_retention_days}' '${var.install_ops_dashboards}' '${var.dashboards_github_repo}' '${var.dashboards_github_branch}'"
    ]
  }
}

# =============================================================================
# WAIT FOR SERVICES TO BE READY
# =============================================================================

resource "null_resource" "verify_monitoring" {
  depends_on = [null_resource.install_monitoring]

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_path)
    host        = var.bastion_public_ip
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for Prometheus to be ready...'",
      "for i in $(seq 1 30); do curl -s http://localhost:${var.prometheus_port}/-/ready > /dev/null && break || sleep 2; done",
      "echo 'Waiting for Grafana to be ready...'",
      "for i in $(seq 1 30); do curl -s http://localhost:${var.grafana_port}/api/health > /dev/null && break || sleep 2; done",
      "echo ''",
      "echo '==================================================================='",
      "echo 'Redis Enterprise Monitoring Stack Ready'",
      "echo '==================================================================='",
      "echo ''",
      "echo 'Prometheus: http://${var.bastion_public_ip}:${var.prometheus_port}'",
      "echo 'Grafana:    http://${var.bastion_public_ip}:${var.grafana_port}'",
      "echo ''",
      "echo 'Grafana credentials:'",
      "echo '  Username: ${var.grafana_admin_user}'",
      "echo '  Password: (see terraform output)'",
      "echo ''",
      "echo 'Scraping Redis Enterprise cluster: ${var.redis_cluster_fqdn}:${var.redis_metrics_port}${local.metrics_path}'",
      "echo '==================================================================='"
    ]
  }
}
