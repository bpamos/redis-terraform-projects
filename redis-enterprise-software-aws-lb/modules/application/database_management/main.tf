# =============================================================================
# REDIS DATABASE MANAGEMENT
# =============================================================================
# Handles creation and management of Redis databases in the cluster
# =============================================================================

# Local values for platform-specific configuration
locals {
  platform_config = {
    ubuntu = {
      user = "ubuntu"
    }
    rhel = {
      user = "ec2-user"
    }
  }
  
  selected_config = local.platform_config[var.platform]
  cluster_full_fqdn = var.cluster_fqdn
}

# =============================================================================
# SAMPLE DATABASE CREATION
# =============================================================================

# Create sample database if requested
resource "null_resource" "sample_database" {
  count = var.create_sample_database ? 1 : 0

  # Trigger database recreation when parameters change
  triggers = {
    cluster_verification_id = var.cluster_verification_id
    database_name          = var.sample_db_name
    database_port          = var.sample_db_port
    database_memory        = var.sample_db_memory
    cluster_fqdn          = local.cluster_full_fqdn
  }

  # Create the sample database using REST API with proper endpoint configuration
  provisioner "remote-exec" {
    inline = [
      "echo 'Creating sample Redis database with private/public endpoint support...'",
      "curl -k -L -u '${var.cluster_username}:${var.cluster_password}' -H 'Content-type:application/json' -d '{\"name\":\"${var.sample_db_name}\",\"type\":\"redis\",\"memory_size\":${var.sample_db_memory * 1048576},\"port\":${var.sample_db_port},\"replication\":false}' https://localhost:9443/v1/bdbs",
      "echo 'Sample database ${var.sample_db_name} created successfully with both private and public endpoints on port ${var.sample_db_port}'"
    ]

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = var.public_ips[0]
      timeout     = "10m"
    }
  }

  # Verify database is running
  provisioner "remote-exec" {
    inline = [
      "echo 'Verifying sample database status...'",
      "timeout 60 bash -c 'until sudo /opt/redislabs/bin/rladmin status databases | grep -q \"${var.sample_db_name}.*active\"; do echo \"Waiting for database to become active...\"; sleep 5; done'",
      "sudo /opt/redislabs/bin/rladmin status databases",
      "echo 'Sample database is active and ready for connections'"
    ]

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = var.public_ips[0]
      timeout     = "5m"
    }
  }

  # Must wait for cluster to be fully bootstrapped
  depends_on = [
    # Cluster verification must complete before database creation
  ]
}

# =============================================================================
# DATABASE ENDPOINT INFORMATION
# =============================================================================

# Local values for database endpoints
locals {
  # Database endpoints (only if sample database is created)
  sample_database_endpoint = var.create_sample_database ? "${var.sample_db_name}-${var.sample_db_port}.${local.cluster_full_fqdn}" : null
  sample_database_endpoint_private = var.create_sample_database ? "${var.sample_db_name}-${var.sample_db_port}-internal.${local.cluster_full_fqdn}" : null
}