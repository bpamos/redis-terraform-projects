# =============================================================================
# OBSERVABILITY MODULE - PROMETHEUS AND GRAFANA FOR REDIS CLOUD
# =============================================================================

# Create observability setup script
resource "null_resource" "observability_setup" {
  triggers = {
    redis_endpoint = var.redis_cloud_endpoint
    instance_id    = var.instance_id
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.ssh_private_key_path)
    host        = var.instance_public_ip
  }

  # Upload docker-compose and configuration files
  provisioner "file" {
    content = templatefile("${path.module}/scripts/docker-compose.yml.tpl", {
      prometheus_config_path = "/home/ubuntu/prometheus/prometheus.yml"
      grafana_config_path    = "/home/ubuntu/grafana/provisioning"
    })
    destination = "/home/ubuntu/docker-compose.yml"
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/prometheus.yml.tpl", {
      redis_endpoint = var.redis_cloud_endpoint
    })
    destination = "/home/ubuntu/prometheus-config.yml"
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/grafana-datasource.yml.tpl", {})
    destination = "/home/ubuntu/grafana-datasource.yml"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/setup-observability.sh"
    destination = "/home/ubuntu/setup-observability.sh"
  }

  # Execute the observability setup script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/setup-observability.sh",
      "/home/ubuntu/setup-observability.sh"
    ]
  }

  depends_on = [var.depends_on_resources]
}