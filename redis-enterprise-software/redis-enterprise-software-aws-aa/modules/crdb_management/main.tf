# =============================================================================
# CRDB (ACTIVE-ACTIVE) DATABASE MANAGEMENT
# =============================================================================
# Creates and manages Redis Enterprise Active-Active (CRDB) databases
# across multiple participating clusters using REST API
# =============================================================================

# Local values for CRDB configuration
locals {
  # Primary cluster (first region alphabetically) for CRDB creation
  primary_region = sort(keys(var.participating_clusters))[0]
  # Use primary node IP for API access (FQDNs may not resolve from local machine)
  primary_cluster_api_url = "https://${var.participating_clusters[local.primary_region].primary_node_ip}:9443"
  # FQDN is still used in CRDB config for cluster-to-cluster communication
  primary_cluster_url = "https://${var.participating_clusters[local.primary_region].cluster_fqdn}:9443"

  # Generate instances list for all participating clusters
  crdb_instances = [
    for region, config in var.participating_clusters : {
      cluster = {
        name = config.cluster_fqdn
        url  = "https://${config.cluster_fqdn}:9443"
        credentials = {
          username = var.cluster_username
          password = var.cluster_password
        }
      }
      compression = 6
    }
  ]

  # CRDB configuration JSON (matching Redis Enterprise API structure)
  crdb_config = {
    name      = var.crdb_name
    instances = local.crdb_instances
    default_db_config = {
      name            = var.crdb_name
      memory_size     = var.crdb_memory_size
      port            = var.crdb_port
      bigstore        = false
      replication     = var.enable_replication
      aof_policy      = var.aof_policy
      snapshot_policy = []
      sharding        = var.enable_sharding
      shards_count    = var.shards_count
    }
  }
}

# =============================================================================
# CRDB CONFIGURATION FILE
# =============================================================================

# Write CRDB configuration to JSON file for API call
resource "local_file" "crdb_config" {
  content  = jsonencode(local.crdb_config)
  filename = "${path.module}/crdb_config_${var.crdb_name}.json"

  # Ensure file permissions are secure
  file_permission = "0600"
}

# =============================================================================
# CRDB CREATION VIA REST API
# =============================================================================

# Create CRDB database using Redis Enterprise REST API
resource "null_resource" "create_crdb" {
  count = var.create_crdb ? 1 : 0

  # Trigger recreation if configuration changes
  triggers = {
    crdb_config_hash = md5(jsonencode(local.crdb_config))
  }

  # Create CRDB via REST API
  provisioner "local-exec" {
    command = <<-EOT
      echo "Creating Active-Active CRDB database: ${var.crdb_name}"
      echo "Primary cluster FQDN: ${local.primary_cluster_url}"
      echo "Primary cluster API: ${local.primary_cluster_api_url}"
      echo "Participating regions: ${join(", ", keys(var.participating_clusters))}"

      # Wait for clusters to be ready
      sleep 30

      # Create CRDB database (using IP for API access)
      response=$(curl -k -s -w "\n%%{http_code}" \
        -u "${var.cluster_username}:${var.cluster_password}" \
        -X POST ${local.primary_cluster_api_url}/v1/crdbs \
        -H "Content-Type: application/json" \
        -d @${local_file.crdb_config.filename})

      http_code=$(echo "$response" | tail -n1)
      response_body=$(echo "$response" | sed '$d')

      echo "HTTP Status: $http_code"
      echo "Response: $response_body"

      # Check if creation was successful (200-299 status codes)
      if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo "✅ CRDB database created successfully!"
        echo "$response_body" > ${path.module}/crdb_creation_response.json
        exit 0
      else
        echo "❌ Failed to create CRDB database"
        echo "Status code: $http_code"
        echo "Response: $response_body"
        exit 1
      fi
    EOT
  }

  # Delete CRDB when destroying (optional - commented out for safety)
  # provisioner "local-exec" {
  #   when    = destroy
  #   command = <<-EOT
  #     echo "Note: CRDB deletion should be done manually via UI or API"
  #     echo "This prevents accidental data loss"
  #   EOT
  # }

  depends_on = [local_file.crdb_config]
}

# =============================================================================
# CRDB VERIFICATION
# =============================================================================

# Verify CRDB exists on all participating clusters
resource "null_resource" "verify_crdb" {
  count = var.create_crdb && var.verify_crdb ? 1 : 0

  # Run verification after CRDB creation
  depends_on = [null_resource.create_crdb]

  # Verify on all clusters
  provisioner "local-exec" {
    command = <<-EOT
      echo "Verifying CRDB database on all participating clusters..."

      sleep 10  # Wait for replication to propagate

      %{for region, config in var.participating_clusters~}
      echo ""
      echo "Checking ${region} cluster (${config.cluster_fqdn})..."
      curl -k -s \
        -u "${var.cluster_username}:${var.cluster_password}" \
        https://${config.primary_node_ip}:9443/v1/crdbs | \
        jq '.[] | select(.name=="${var.crdb_name}") | {name, status, instances: .instances | length}'
      %{endfor~}

      echo ""
      echo "✅ CRDB verification complete"
    EOT
  }
}
