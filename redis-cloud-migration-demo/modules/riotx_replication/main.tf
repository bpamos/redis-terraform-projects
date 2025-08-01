# =============================================================================
# RIOT-X REPLICATION SETUP
# =============================================================================

# Upload and configure the RIOT-X replication script
resource "null_resource" "upload_riotx_script" {
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.ssh_private_key_path)
    host        = var.ec2_public_ip
  }

  # Upload the script template
  provisioner "file" {
    content = templatefile("${path.module}/scripts/start_riotx.sh", {
      elasticache_endpoint      = var.elasticache_endpoint
      rediscloud_private_endpoint = var.rediscloud_private_endpoint
      rediscloud_password       = var.rediscloud_password
      replication_mode         = var.replication_mode
      enable_metrics           = var.enable_metrics
      metrics_port             = var.metrics_port
      log_keys                = var.log_keys
    })
    destination = "/home/ubuntu/start_riotx.sh"
  }

  # Make script executable and validate
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/start_riotx.sh",
      "echo \"RIOT-X script uploaded and configured successfully\""
    ]
  }
}

# Validate connectivity before starting replication
resource "null_resource" "validate_connectivity" {
  depends_on = [null_resource.upload_riotx_script]
  
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.ssh_private_key_path)
    host        = var.ec2_public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "echo \"Validating Redis connectivity...\"",
      "redis-cli -h ${var.elasticache_endpoint} -p 6379 ping || (echo \"ElastiCache connection failed\" && exit 1)",
      "echo \"ElastiCache connectivity validated\"",
      "echo \"Redis Cloud connectivity will be validated by RIOT-X script\""
    ]
  }
}

# Start RIOT-X replication
resource "null_resource" "start_riotx_replication" {
  depends_on = [null_resource.validate_connectivity]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.ssh_private_key_path)
    host        = var.ec2_public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y && sudo apt-get install -y at",
      "echo \"Starting RIOT-X replication in background...\"",
      "nohup /home/ubuntu/start_riotx.sh > /home/ubuntu/riotx_startup.log 2>&1 &",
      "sleep 5",
      "echo \"RIOT-X replication started. Check logs with: tail -f /home/ubuntu/riotx.log\""
    ]
  }
}

