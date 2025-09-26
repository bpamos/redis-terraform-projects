# =============================================================================
# REDIS ENTERPRISE CLUSTER BOOTSTRAP
# =============================================================================
# Handles cluster creation and node joining operations
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
# PRIMARY NODE: CREATE CLUSTER
# =============================================================================

# Create cluster on primary node (node 0)
resource "null_resource" "create_cluster" {
  # Trigger cluster recreation when critical parameters change
  triggers = {
    primary_instance_id = var.instance_ids[0]
    cluster_username    = var.cluster_username
    cluster_password    = var.cluster_password
    cluster_fqdn       = local.cluster_full_fqdn
    rack_awareness     = var.rack_awareness
    flash_enabled      = var.flash_enabled
    installation_id    = var.installation_completion_ids[0]
  }

  # Create cluster and configure external address for private/public endpoints
  provisioner "remote-exec" {
    inline = [
      "echo 'Creating Redis Enterprise cluster...'",
      "echo '${var.cluster_password}' > /tmp/cluster_pass.txt",
      "sudo /opt/redislabs/bin/rladmin cluster create name ${local.cluster_full_fqdn} username ${var.cluster_username} password $(cat /tmp/cluster_pass.txt) register_dns_suffix ${var.flash_enabled ? "flash_enabled" : ""} ${var.rack_awareness ? "rack_aware rack_id ${var.availability_zones[0]}" : ""}",
      "rm -f /tmp/cluster_pass.txt",
      "echo 'Configuring external address for private/public endpoints...'",
      "sudo /opt/redislabs/bin/rladmin node 1 external_addr set ${var.public_ips[0]}",
      "echo 'Cluster created successfully with private/public endpoints enabled'"
    ]

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = var.public_ips[0]
      timeout     = "15m"
    }
  }

  # Wait for cluster to be ready
  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cluster to be ready...'",
      "timeout 300 bash -c 'until sudo /opt/redislabs/bin/rladmin status | grep -q \"cluster state: ok\"; do echo \"Waiting for cluster...\"; sleep 10; done'",
      "echo 'Cluster is ready for node additions'"
    ]

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = var.public_ips[0]
      timeout     = "10m"
    }
  }

  # Must wait for Redis Enterprise installation on primary node
  depends_on = [
    # Installation must complete before cluster creation
  ]
}

# =============================================================================
# REPLICA NODES: JOIN CLUSTER
# =============================================================================

# Join remaining nodes to the cluster
resource "null_resource" "join_cluster" {
  count = var.node_count > 1 ? var.node_count - 1 : 0

  # Trigger when node changes or cluster is recreated
  triggers = {
    instance_id     = var.instance_ids[count.index + 1]
    primary_ip      = var.private_ips[0]
    cluster_created = null_resource.create_cluster.id
    installation_id = var.installation_completion_ids[count.index + 1]
  }

  # Join node to cluster and configure external address
  provisioner "remote-exec" {
    inline = [
      "echo 'Joining node ${count.index + 2} to cluster...'",
      "echo '${var.cluster_password}' > /tmp/cluster_pass.txt",
      "sudo /opt/redislabs/bin/rladmin cluster join nodes ${var.private_ips[0]} username ${var.cluster_username} password $(cat /tmp/cluster_pass.txt) ${var.flash_enabled ? "flash_enabled" : ""} ${var.rack_awareness ? "rack_id ${var.availability_zones[count.index + 1]}" : ""}",
      "rm -f /tmp/cluster_pass.txt",
      "echo 'Configuring external address for node ${count.index + 2}...'",
      "sudo /opt/redislabs/bin/rladmin node ${count.index + 2} external_addr set ${var.public_ips[count.index + 1]}",
      "echo 'Node ${count.index + 2} joined cluster successfully with external address'"
    ]

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = var.public_ips[count.index + 1]
      timeout     = "15m"
    }
  }

  # Verify node joined successfully
  provisioner "remote-exec" {
    inline = [
      "echo 'Verifying node ${count.index + 2} cluster membership...'",
      "timeout 120 bash -c 'until sudo /opt/redislabs/bin/rladmin status | grep -q \"node:${count.index + 2}\"; do echo \"Waiting for node to appear in cluster...\"; sleep 10; done'",
      "echo 'Node ${count.index + 2} successfully joined and verified in cluster'"
    ]

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = var.public_ips[count.index + 1]
      timeout     = "10m"
    }
  }

  # Must wait for cluster creation and installation on this node
  depends_on = [
    null_resource.create_cluster
  ]
}

# =============================================================================
# FINAL CLUSTER VERIFICATION
# =============================================================================

# Final verification that all nodes are healthy
resource "null_resource" "cluster_verification" {
  # Trigger when cluster composition changes
  triggers = {
    cluster_created = null_resource.create_cluster.id
    nodes_joined    = length(null_resource.join_cluster) > 0 ? join(",", null_resource.join_cluster[*].id) : "no-replicas"
    node_count      = var.node_count
  }

  # Verify cluster health
  provisioner "remote-exec" {
    inline = [
      "echo 'Performing final cluster verification...'",
      "sudo /opt/redislabs/bin/rladmin status",
      "echo 'Checking cluster state...'",
      "sudo /opt/redislabs/bin/rladmin info cluster",
      "echo 'Redis Enterprise cluster setup completed successfully with ${var.node_count} nodes'"
    ]

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = var.public_ips[0]
      timeout     = "10m"
    }
  }

  # Wait for all nodes to join before final verification
  depends_on = [
    null_resource.create_cluster,
    null_resource.join_cluster
  ]
}

# =============================================================================
# LOAD BALANCER CONFIGURATION
# =============================================================================

# Configure cluster for load balancer compatibility
resource "null_resource" "load_balancer_config" {
  # Trigger when cluster is ready
  triggers = {
    cluster_verified = null_resource.cluster_verification.id
  }

  # Apply load balancer-specific cluster configuration
  provisioner "remote-exec" {
    inline = [
      "echo 'Configuring cluster for load balancer compatibility...'",
      
      # Configure proxy policies for load balancer compatibility
      "echo 'Setting proxy policies: all-nodes for both sharded and non-sharded databases...'",
      "sudo /opt/redislabs/bin/rladmin tune cluster default_sharded_proxy_policy all-nodes default_non_sharded_proxy_policy all-nodes",
      
      # Enable handle_redirects for load balancer compatibility
      "echo 'Enabling handle_redirects for load balancer compatibility...'",
      "sudo /opt/redislabs/bin/rladmin cluster config handle_redirects enabled",
      
      # Optional: Enable sparse shard placement for better load balancing
      "echo 'Enabling sparse shard placement for optimal load balancing...'",
      "sudo /opt/redislabs/bin/rladmin tune cluster default_shards_placement sparse",
      
      # Verify configuration
      "echo 'Verifying load balancer configuration...'",
      "sudo /opt/redislabs/bin/rladmin info cluster | grep -E 'default_.*_proxy_policy|handle_redirects|default_shards_placement'",
      
      "echo 'Load balancer configuration completed successfully'"
    ]

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = var.public_ips[0]
      timeout     = "10m"
    }
  }

  # Wait for cluster verification to complete
  depends_on = [
    null_resource.cluster_verification
  ]
}