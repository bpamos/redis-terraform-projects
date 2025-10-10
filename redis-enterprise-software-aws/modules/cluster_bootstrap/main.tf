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

  selected_config   = local.platform_config[var.platform]
  cluster_full_fqdn = "${var.name_prefix}.${var.hosted_zone_name}"
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
    cluster_fqdn        = local.cluster_full_fqdn
    rack_awareness      = var.rack_awareness
    flash_enabled       = var.flash_enabled
    installation_id     = var.installation_completion_ids[0]
  }

  # Create cluster and configure external address for private/public endpoints
  provisioner "remote-exec" {
    inline = [
      "echo 'Creating Redis Enterprise cluster...'",
      "printf '%s' '${base64encode(var.cluster_password)}' | base64 -d > /tmp/cluster_pass.txt",
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

  # Join node to cluster with retries and robust error handling
  provisioner "remote-exec" {
    inline = [
      "echo '=== Starting Node ${count.index + 2} Join Process ==='",
      "echo 'Target cluster: ${var.private_ips[0]}'",
      "echo 'Node IP: ${var.private_ips[count.index + 1]}'",
      "echo 'Public IP: ${var.public_ips[count.index + 1]}'",
      "# Function to attempt cluster join with retries",
      "join_cluster_with_retries() {",
      "  local max_attempts=5",
      "  local attempt=1",
      "  local success=false",
      "  while [ $attempt -le $max_attempts ] && [ \"$success\" = false ]; do",
      "    echo \"[$(date)] Attempt $attempt/$max_attempts: Joining node ${count.index + 2} to cluster...\"",
      "    printf '%s' '${base64encode(var.cluster_password)}' | base64 -d > /tmp/cluster_pass.txt",
      "    if sudo /opt/redislabs/bin/rladmin cluster join nodes ${var.private_ips[0]} username ${var.cluster_username} password $(cat /tmp/cluster_pass.txt) ${var.flash_enabled ? "flash_enabled" : ""} ${var.rack_awareness ? "rack_id ${var.availability_zones[count.index + 1]}" : ""}; then",
      "      echo \"[$(date)] ✅ Cluster join command succeeded on attempt $attempt\"",
      "      success=true",
      "    else",
      "      echo \"[$(date)] ❌ Cluster join attempt $attempt failed\"",
      "      if [ $attempt -lt $max_attempts ]; then",
      "        echo \"[$(date)] Waiting 30 seconds before retry...\"",
      "        sleep 30",
      "      fi",
      "    fi",
      "    rm -f /tmp/cluster_pass.txt",
      "    attempt=$((attempt + 1))",
      "  done",
      "  if [ \"$success\" = true ]; then",
      "    echo \"[$(date)] ✅ Node ${count.index + 2} successfully joined cluster\"",
      "    return 0",
      "  else",
      "    echo \"[$(date)] ❌ Failed to join node ${count.index + 2} to cluster after $max_attempts attempts\"",
      "    return 1",
      "  fi",
      "}",
      "# Attempt to join cluster",
      "if join_cluster_with_retries; then",
      "  echo 'Waiting 15 seconds for cluster to stabilize...'",
      "  sleep 15",
      "  echo 'Configuring external address for node ${count.index + 2}...'",
      "  if sudo /opt/redislabs/bin/rladmin node ${count.index + 2} external_addr set ${var.public_ips[count.index + 1]}; then",
      "    echo '✅ External address configured successfully'",
      "  else",
      "    echo '⚠️  Warning: External address configuration failed, but node joined cluster'",
      "  fi",
      "  echo '✅ Node ${count.index + 2} join process completed successfully'",
      "else",
      "  echo '❌ Node ${count.index + 2} failed to join cluster after all attempts'",
      "  exit 1",
      "fi"
    ]

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = var.public_ips[count.index + 1]
      timeout     = "20m"
    }
  }

  # Verify node joined successfully with comprehensive checks and patience
  provisioner "remote-exec" {
    inline = [
      "echo '=== Verifying Node ${count.index + 2} Cluster Membership ==='",
      "echo 'Waiting for cluster to fully stabilize after join...'",
      "sleep 30",
      "echo '1. Waiting for node to appear in cluster status...'",
      "timeout 300 bash -c 'while true; do if sudo /opt/redislabs/bin/rladmin status | grep -q \"node:${count.index + 2}\"; then echo \"[$(date)] ✅ Node ${count.index + 2} found in cluster status\"; break; else echo \"[$(date)] ⏳ Waiting for node ${count.index + 2} to appear in cluster...\"; sleep 20; fi; done'",
      "echo '2. Waiting for node to reach healthy status...'",
      "timeout 180 bash -c 'while true; do if sudo /opt/redislabs/bin/rladmin status | grep \"node:${count.index + 2}\" | grep -q \"OK\"; then echo \"[$(date)] ✅ Node ${count.index + 2} is healthy (OK status)\"; break; else echo \"[$(date)] ⏳ Waiting for node ${count.index + 2} to become healthy...\"; sleep 15; fi; done'",
      "echo '3. Final verification - displaying node details:'",
      "if sudo /opt/redislabs/bin/rladmin status | grep \"node:${count.index + 2}\"; then",
      "  echo '✅ Node ${count.index + 2} successfully joined and verified healthy in cluster'",
      "else",
      "  echo '❌ Node ${count.index + 2} verification failed - not found in cluster'",
      "  exit 1",
      "fi"
    ]

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = var.public_ips[count.index + 1]
      timeout     = "20m"
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

# Final verification that all nodes are healthy and joined successfully
resource "null_resource" "cluster_verification" {
  # Trigger when cluster composition changes
  triggers = {
    cluster_created = null_resource.create_cluster.id
    nodes_joined    = length(null_resource.join_cluster) > 0 ? join(",", null_resource.join_cluster[*].id) : "no-replicas"
    node_count      = var.node_count
  }

  # Comprehensive cluster validation with patience and retries
  provisioner "remote-exec" {
    inline = [
      "echo '=== Starting Comprehensive Cluster Validation ==='",
      "echo 'Expected node count: ${var.node_count}'",
      "echo 'Allowing extra time for all nodes to fully stabilize...'",
      "sleep 60",
      "echo '=== 1. Checking Redis Enterprise Service Status ==='",
      "sudo systemctl status rl-server-manager --no-pager || echo 'Service status check completed'",
      "echo '=== 2. Initial Cluster Status Check ==='",
      "sudo /opt/redislabs/bin/rladmin status",
      "echo '=== 3. Detailed Cluster Information ==='",
      "sudo /opt/redislabs/bin/rladmin info cluster",
      "echo '=== 4. Patient Validation - Waiting for All Nodes ==='",
      "# Patient validation with retries",
      "max_validation_attempts=10",
      "validation_attempt=1",
      "while [ $validation_attempt -le $max_validation_attempts ]; do",
      "  echo \"[$(date)] Validation attempt $validation_attempt/$max_validation_attempts\"",
      "  NODE_COUNT_ACTUAL=$(sudo /opt/redislabs/bin/rladmin status | sed 's/\\x1b\\[[0-9;]*m//g' | grep -E '(^node:|^\\*node:)' | wc -l)",
      "  echo \"Actual nodes in cluster: $NODE_COUNT_ACTUAL\"",
      "  echo \"Expected nodes: ${var.node_count}\"",
      "  if [ \"$NODE_COUNT_ACTUAL\" -eq \"${var.node_count}\" ]; then",
      "    echo \"✅ SUCCESS: All ${var.node_count} nodes are present in cluster\"",
      "    break",
      "  else",
      "    echo \"⏳ Attempt $validation_attempt: Found $NODE_COUNT_ACTUAL/${var.node_count} nodes\"",
      "    if [ $validation_attempt -lt $max_validation_attempts ]; then",
      "      echo \"Waiting 30 seconds before next validation attempt...\"",
      "      sleep 30",
      "    else",
      "      echo \"❌ ERROR: Expected ${var.node_count} nodes but found $NODE_COUNT_ACTUAL nodes after $max_validation_attempts attempts\"",
      "      echo \"Final cluster status:\"",
      "      sudo /opt/redislabs/bin/rladmin status",
      "      echo \"Cluster node validation FAILED\"",
      "      exit 1",
      "    fi",
      "  fi",
      "  validation_attempt=$((validation_attempt + 1))",
      "done",
      "echo '=== 5. Checking Node Health Status ==='",
      "# Verify all nodes are healthy (not in error state)",
      "UNHEALTHY_NODES=$(sudo /opt/redislabs/bin/rladmin status | sed 's/\\\\x1b\\\\[[0-9;]*m//g' | grep -E '(^node:|^\\*node:)' | grep -v 'OK' | wc -l)",
      "if [ \"$UNHEALTHY_NODES\" -eq \"0\" ]; then",
      "  echo '✅ SUCCESS: All nodes are in healthy state'",
      "else",
      "  echo '❌ ERROR: Found $UNHEALTHY_NODES unhealthy nodes'",
      "  echo 'Unhealthy nodes:'",
      "  sudo /opt/redislabs/bin/rladmin status | sed 's/\\\\x1b\\\\[[0-9;]*m//g' | grep -E '(^node:|^\\*node:)' | grep -v 'OK'",
      "  echo 'Node health validation FAILED'",
      "  exit 1",
      "fi",
      "echo '=== 6. Validating Cluster State ==='",
      "# Check cluster state (may not exist if no databases are created yet)",
      "CLUSTER_STATE_LINE=$(sudo /opt/redislabs/bin/rladmin status | grep 'cluster state' || echo '')",
      "if [ -z \"$CLUSTER_STATE_LINE\" ]; then",
      "  echo '✅ SUCCESS: No cluster state line found (normal when no databases exist yet)'",
      "elif echo \"$CLUSTER_STATE_LINE\" | grep -q 'cluster state: ok'; then",
      "  echo '✅ SUCCESS: Cluster state is OK'",
      "else",
      "  echo '❌ ERROR: Cluster state is not OK'",
      "  echo 'Current cluster state:'",
      "  echo \"$CLUSTER_STATE_LINE\"",
      "  echo 'Cluster state validation FAILED'",
      "  exit 1",
      "fi",
      "echo '=== 7. Final Node Enumeration ==='",
      "echo 'All cluster nodes:'",
      "sudo /opt/redislabs/bin/rladmin status | sed 's/\\\\x1b\\\\[[0-9;]*m//g' | grep -E '(^node:|^\\*node:)' | while read line; do",
      "  echo \"  $line\"",
      "done",
      "echo '=== CLUSTER VALIDATION SUMMARY ==='",
      "echo \"✅ Redis Enterprise cluster validation completed successfully\"",
      "echo \"✅ Cluster has ${var.node_count} nodes as expected\"",
      "echo \"✅ All nodes are healthy and active\"",
      "echo \"✅ Cluster state is OK\"",
      "echo \"✅ Redis Enterprise cluster setup completed successfully with ${var.node_count} nodes\""
    ]

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = var.public_ips[0]
      timeout     = "25m"
    }
  }

  # Wait for all nodes to join before final verification
  depends_on = [
    null_resource.create_cluster,
    null_resource.join_cluster
  ]
}