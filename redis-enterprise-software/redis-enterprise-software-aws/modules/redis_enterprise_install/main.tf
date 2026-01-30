# =============================================================================
# REDIS ENTERPRISE SOFTWARE INSTALLATION
# =============================================================================
# Handles Redis Enterprise software installation on provisioned instances
# =============================================================================

# Local values for platform-specific configuration
locals {
  platform_config = {
    ubuntu = {
      user           = "ubuntu"
      install_script = "install_redis_enterprise_ubuntu.sh"
    }
    rhel = {
      user           = "ec2-user"
      install_script = "install_redis_enterprise_rhel.sh"
    }
  }

  selected_config = local.platform_config[var.platform]
}

# Install Redis Enterprise software on each node
resource "null_resource" "redis_enterprise_installation" {
  count = var.node_count

  # Trigger reinstallation when critical parameters change
  triggers = {
    instance_id          = var.instance_ids[count.index]
    re_download_url      = var.re_download_url
    platform             = var.platform
    data_volume_id       = var.data_volume_attachment_ids[count.index]
    persistent_volume_id = var.persistent_volume_attachment_ids[count.index]
  }

  # Wait for basic system setup to complete
  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for basic system setup to complete...'",
      "timeout 300 bash -c 'while [ ! -f /tmp/basic-setup-complete ]; do echo \"Waiting for basic setup...\"; sleep 10; done'",
      "echo 'Basic setup completed, ready for Redis Enterprise installation'"
    ]

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = var.public_ips[count.index]
      timeout     = "15m"
    }
  }

  # Install Redis Enterprise software
  provisioner "file" {
    source      = "${path.module}/scripts/${local.selected_config.install_script}"
    destination = "/tmp/install_redis_enterprise.sh"

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = var.public_ips[count.index]
      timeout     = "15m"
    }
  }

  # Execute installation script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_redis_enterprise.sh",
      "/tmp/install_redis_enterprise.sh '${var.re_download_url}'"
    ]

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = var.public_ips[count.index]
      timeout     = "30m"
    }
  }

  # Ensure installation completed successfully and create completion marker
  provisioner "remote-exec" {
    inline = [
      "echo 'Verifying Redis Enterprise installation...'",
      "timeout 300 bash -c 'until sudo /opt/redislabs/bin/supervisorctl status | grep -q \"bootstrap_mgr.*RUNNING\"; do echo \"Waiting for Redis Enterprise services...\"; sleep 10; done'",
      "echo 'Creating installation completion marker...'",
      "sudo touch /tmp/redis-enterprise-install-complete",
      "echo 'Redis Enterprise installation completed successfully on node ${count.index + 1}'"
    ]

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = var.public_ips[count.index]
      timeout     = "15m"
    }
  }
}