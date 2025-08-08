# =============================================================================
# REDIS ENTERPRISE SOFTWARE CLUSTER
# =============================================================================
# Creates EC2 instances for Redis Enterprise Software 3-node cluster
# =============================================================================

# =============================================================================
# EBS VOLUMES FOR REDIS DATA AND PERSISTENCE
# =============================================================================

# Data volume for each Redis Enterprise node
resource "aws_ebs_volume" "redis_data" {
  count             = var.node_count
  availability_zone = data.aws_subnet.selected[count.index].availability_zone
  size              = var.data_volume_size
  type              = var.data_volume_type
  encrypted         = var.ebs_encryption_enabled
  
  tags = merge(
    {
      Name    = "${var.name_prefix}-redis-data-${count.index + 1}"
      Owner   = var.owner
      Project = var.project
      Type    = "Redis-Data-Volume"
    },
    var.tags
  )
}

# Persistent storage volume for each Redis Enterprise node
resource "aws_ebs_volume" "redis_persistent" {
  count             = var.node_count
  availability_zone = data.aws_subnet.selected[count.index].availability_zone
  size              = var.persistent_volume_size
  type              = var.persistent_volume_type
  encrypted         = var.ebs_encryption_enabled
  
  tags = merge(
    {
      Name    = "${var.name_prefix}-redis-persistent-${count.index + 1}"
      Owner   = var.owner
      Project = var.project
      Type    = "Redis-Persistent-Volume"
    },
    var.tags
  )
}

# =============================================================================
# EC2 INSTANCES FOR REDIS ENTERPRISE CLUSTER
# =============================================================================

# Redis Enterprise cluster nodes
resource "aws_instance" "redis_enterprise_nodes" {
  count                  = var.node_count
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name              = var.key_name
  vpc_security_group_ids = [var.security_group_id]
  subnet_id             = var.subnet_ids[count.index % length(var.subnet_ids)]
  
  # Associate public IP for initial setup (can be disabled later for production)
  associate_public_ip_address = true
  
  # Root volume configuration
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.node_root_size
    encrypted            = var.ebs_encryption_enabled
    delete_on_termination = true
    
    tags = merge(
      {
        Name    = "${var.name_prefix}-redis-root-${count.index + 1}"
        Owner   = var.owner
        Project = var.project
      },
      var.tags
    )
  }

  # Minimal user data for basic setup only
  user_data = base64encode(templatefile("${path.module}/scripts/${local.selected_config.basic_setup_script}", {
    hostname = "${var.name_prefix}-redis-node-${count.index + 1}"
    platform = var.platform
  }))

  tags = merge(
    {
      Name    = "${var.name_prefix}-redis-node-${count.index + 1}"
      Owner   = var.owner
      Project = var.project
      Type    = "Redis-Enterprise-Node"
      Role    = count.index == 0 ? "primary" : "replica"
    },
    var.tags
  )

  # Ensure instances are created one at a time to avoid race conditions
  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# EBS VOLUME ATTACHMENTS
# =============================================================================

# Attach data volumes to Redis Enterprise nodes
resource "aws_volume_attachment" "redis_data_attachment" {
  count       = var.node_count
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.redis_data[count.index].id
  instance_id = aws_instance.redis_enterprise_nodes[count.index].id
}

# Attach persistent volumes to Redis Enterprise nodes
resource "aws_volume_attachment" "redis_persistent_attachment" {
  count       = var.node_count
  device_name = "/dev/sdg"
  volume_id   = aws_ebs_volume.redis_persistent[count.index].id
  instance_id = aws_instance.redis_enterprise_nodes[count.index].id
}

# =============================================================================
# DATA SOURCES
# =============================================================================

# Get subnet information for availability zone placement
data "aws_subnet" "selected" {
  count = var.node_count
  id    = var.subnet_ids[count.index % length(var.subnet_ids)]
}

# Get hosted zone information for constructing full FQDN
data "aws_route53_zone" "main" {
  zone_id = var.dns_hosted_zone_id
}

# Local values for configuration
locals {
  cluster_full_fqdn = "${var.name_prefix}.${data.aws_route53_zone.main.name}"
  
  # Platform-specific configuration
  platform_config = {
    ubuntu = {
      user                = "ubuntu"
      install_script      = "install_redis_enterprise_ubuntu.sh"
      basic_setup_script  = "basic_setup_ubuntu.sh"
    }
    rhel = {
      user                = "ec2-user"
      install_script      = "install_redis_enterprise_rhel.sh"
      basic_setup_script  = "basic_setup_rhel.sh"
    }
  }
  
  # Select configuration based on platform
  selected_config = local.platform_config[var.platform]
  
  # Use provided URL (required)
  actual_re_download_url = var.re_download_url
}

# =============================================================================
# REDIS ENTERPRISE SOFTWARE INSTALLATION
# =============================================================================

# Wait for basic setup to complete and install Redis Enterprise
resource "null_resource" "redis_enterprise_installation" {
  count = var.node_count

  # Trigger when instance or volumes change
  triggers = {
    instance_id = aws_instance.redis_enterprise_nodes[count.index].id
    data_volume = aws_volume_attachment.redis_data_attachment[count.index].id
    persistent_volume = aws_volume_attachment.redis_persistent_attachment[count.index].id
    re_download_url = local.actual_re_download_url
    platform = var.platform
    cluster_config = "${var.cluster_username}-${var.cluster_password}-${local.cluster_full_fqdn}"
  }

  # Wait for basic setup to complete
  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for basic system setup to complete...'",
      "timeout 300 bash -c 'while [ ! -f /tmp/basic-setup-complete ]; do echo \"Waiting for basic setup...\"; sleep 10; done'",
      "echo 'Basic setup completed, starting Redis Enterprise installation'"
    ]

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.redis_enterprise_nodes[count.index].public_ip
      timeout     = "15m"
    }
  }

  # Copy Redis Enterprise installation script
  provisioner "file" {
    source      = "${path.module}/scripts/${local.selected_config.install_script}"
    destination = "/tmp/install_redis_enterprise.sh"

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.redis_enterprise_nodes[count.index].public_ip
    }
  }

  # Install Redis Enterprise
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_redis_enterprise.sh",
      "/tmp/install_redis_enterprise.sh '${local.actual_re_download_url}' '${count.index + 1}' '${count.index == 0 ? "true" : "false"}' '${local.cluster_full_fqdn}' '${var.cluster_username}' '${var.cluster_password}' '${var.flash_enabled}' '${var.rack_awareness}' '${var.platform}'"
    ]

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.redis_enterprise_nodes[count.index].public_ip
      timeout     = "15m"
    }
  }

  depends_on = [
    aws_volume_attachment.redis_data_attachment,
    aws_volume_attachment.redis_persistent_attachment
  ]
}

# =============================================================================
# CLUSTER INITIALIZATION (Primary Node Only)
# =============================================================================

resource "null_resource" "redis_cluster_init" {
  # Only run on primary node (index 0)
  count = 1

  triggers = {
    cluster_config = "${var.cluster_username}-${var.cluster_password}-${local.cluster_full_fqdn}"
    installation_complete = null_resource.redis_enterprise_installation[0].id
  }

  # Initialize Redis Enterprise cluster
  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for Redis Enterprise to be ready for cluster operations...'",
      "# Wait for Redis Enterprise services to be fully ready",
      "echo 'Checking Redis Enterprise service status...'",
      "timeout 300 bash -c 'while ! sudo systemctl is-active --quiet rlec_supervisor; do echo \"Waiting for rlec_supervisor...\"; sleep 5; done'",
      "echo 'rlec_supervisor is active'",
      "# Additional wait to ensure all internal services are ready",
      "echo 'Waiting additional 60 seconds for full service initialization...'",
      "sleep 60",
      "# Check if cluster already exists (idempotent)",
      "if sudo /opt/redislabs/bin/rladmin status >/dev/null 2>&1; then",
      "  echo 'Cluster already exists, skipping initialization'",
      "  sudo /opt/redislabs/bin/rladmin status",
      "else",
      "  echo 'Initializing Redis Enterprise cluster...'",
      "  sudo /opt/redislabs/bin/rladmin cluster create name ${local.cluster_full_fqdn} username ${var.cluster_username} password ${var.cluster_password} external_addr ${aws_instance.redis_enterprise_nodes[0].public_ip} register_dns_suffix ephemeral_path /var/opt/redislabs persistent_path /var/opt/redislabs/persist${var.flash_enabled ? " flash_enabled" : ""}${var.rack_awareness ? " rack_aware rack_id ${data.aws_subnet.selected[0].availability_zone}" : ""}",
      "  # Verify cluster creation",
      "  if sudo /opt/redislabs/bin/rladmin status >/dev/null 2>&1; then",
      "    echo 'Cluster initialized successfully!'",
      "    sudo /opt/redislabs/bin/rladmin status",
      "  else",
      "    echo 'ERROR: Cluster initialization failed'",
      "    exit 1",
      "  fi",
      "fi"
    ]

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.redis_enterprise_nodes[0].public_ip
      timeout     = "10m"
    }
  }

  depends_on = [null_resource.redis_enterprise_installation]
}

# =============================================================================
# NODE JOINING (Replica Nodes)
# =============================================================================

resource "null_resource" "redis_cluster_join" {
  # Run on replica nodes (index 1 and 2)
  count = var.node_count - 1

  triggers = {
    primary_ip = aws_instance.redis_enterprise_nodes[0].private_ip
    cluster_config = "${var.cluster_username}-${var.cluster_password}"
    cluster_init_complete = null_resource.redis_cluster_init[0].id
  }

  # Join nodes to cluster using both private and public IP fallback
  provisioner "remote-exec" {
    inline = [
      "echo 'Joining Redis Enterprise cluster...'",
      "echo 'Primary node private IP: ${aws_instance.redis_enterprise_nodes[0].private_ip}'",
      "echo 'Primary node public IP: ${aws_instance.redis_enterprise_nodes[0].public_ip}'",
      "echo 'Waiting for primary cluster to be fully ready...'",
      "sleep 60",
      "# Function to test cluster join connectivity",
      "test_connectivity() {",
      "  local primary_ip=$1",
      "  echo \"Testing connectivity to $primary_ip:9443...\"",
      "  nc -zv $primary_ip 9443 || return 1",
      "  echo \"Testing connectivity to $primary_ip:8001...\"", 
      "  nc -zv $primary_ip 8001 || return 1",
      "  return 0",
      "}",
      "# Try joining with private IP first, then public IP",
      "join_success=false",
      "# Attempt 1: Private IP",
      "if test_connectivity ${aws_instance.redis_enterprise_nodes[0].private_ip}; then",
      "  echo 'Attempting cluster join with private IP...'",
      "  if sudo /opt/redislabs/bin/rladmin cluster join nodes ${aws_instance.redis_enterprise_nodes[0].private_ip} username ${var.cluster_username} password ${var.cluster_password} external_addr ${aws_instance.redis_enterprise_nodes[count.index + 1].public_ip} ephemeral_path /var/opt/redislabs persistent_path /var/opt/redislabs/persist${var.rack_awareness ? " rack_id ${data.aws_subnet.selected[count.index + 1].availability_zone}" : ""}; then",
      "    join_success=true",
      "    echo 'Successfully joined cluster using private IP!'",
      "  fi",
      "fi",
      "# Attempt 2: Public IP (fallback)",
      "if [ \"$join_success\" = \"false\" ]; then",
      "  echo 'Private IP join failed, trying public IP...'",
      "  if test_connectivity ${aws_instance.redis_enterprise_nodes[0].public_ip}; then",
      "    echo 'Attempting cluster join with public IP...'",
      "    if sudo /opt/redislabs/bin/rladmin cluster join nodes ${aws_instance.redis_enterprise_nodes[0].public_ip} username ${var.cluster_username} password ${var.cluster_password} external_addr ${aws_instance.redis_enterprise_nodes[count.index + 1].public_ip} ephemeral_path /var/opt/redislabs persistent_path /var/opt/redislabs/persist${var.rack_awareness ? " rack_id ${data.aws_subnet.selected[count.index + 1].availability_zone}" : ""}; then",
      "      join_success=true",
      "      echo 'Successfully joined cluster using public IP!'",
      "    fi",
      "  fi",
      "fi",
      "# Check final result",
      "if [ \"$join_success\" = \"true\" ]; then",
      "  echo 'Node successfully joined cluster!'",
      "  sudo /opt/redislabs/bin/rladmin status",
      "else",
      "  echo 'ERROR: Failed to join cluster with both private and public IPs'",
      "  echo 'Check network connectivity and cluster status'",
      "  exit 1",
      "fi"
    ]

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.redis_enterprise_nodes[count.index + 1].public_ip
      timeout     = "15m"
    }
  }

  depends_on = [null_resource.redis_cluster_init]
}

# =============================================================================
# REDIS DATABASE CREATION
# =============================================================================

resource "null_resource" "redis_database_creation" {
  count = var.create_sample_database ? 1 : 0

  triggers = {
    cluster_ready = var.node_count > 1 ? null_resource.redis_cluster_join[var.node_count - 2].id : null_resource.redis_cluster_init[0].id
    database_config = "${var.sample_db_name}-${var.sample_db_port}-${var.sample_db_memory}"
  }

  # Create a sample Redis database
  provisioner "remote-exec" {
    inline = [
      "echo 'Creating Redis database...'",
      "echo 'Waiting for cluster to be fully ready...'",
      "sleep 30",
      "# Create database using REST API - try basic creation first",
      "echo 'Creating database via REST API...'",
      "DB_RESPONSE=$(curl -k -L -u '${var.cluster_username}:${var.cluster_password}' \\",
      "  -H 'Content-Type: application/json' \\",
      "  -X POST https://localhost:9443/v1/bdbs \\",
      "  -d '{",
      "    \"name\": \"${var.sample_db_name}\",",
      "    \"port\": ${var.sample_db_port},",
      "    \"memory_size\": ${var.sample_db_memory * 1024 * 1024},",
      "    \"type\": \"redis\",",
      "    \"replication\": true",
      "  }' -w '%%{http_code}' -o /tmp/db_response.json)",
      "echo \"HTTP Response Code: $DB_RESPONSE\"",
      "echo 'Response Body:'",
      "cat /tmp/db_response.json",
      "if [ \"$DB_RESPONSE\" -ne \"200\" ]; then",
      "  echo 'Database creation failed, checking if it already exists...'",
      "  curl -k -L -u '${var.cluster_username}:${var.cluster_password}' https://localhost:9443/v1/bdbs",
      "  echo 'Attempting to continue anyway...'",
      "fi",
      "# Verify database creation",
      "if sudo /opt/redislabs/bin/rladmin status databases | grep -q ${var.sample_db_name}; then",
      "  echo 'Database created successfully!'",
      "  sudo /opt/redislabs/bin/rladmin status databases",
      "else",
      "  echo 'ERROR: Database creation failed'",
      "  exit 1",
      "fi",
      "# Show database endpoint info",
      "echo 'Database endpoints created:'",
      "echo '  External: ${var.sample_db_name}-${var.sample_db_port}.${local.cluster_full_fqdn}:${var.sample_db_port}'",
      "echo '  Internal: ${var.sample_db_name}-${var.sample_db_port}-internal.${local.cluster_full_fqdn}:${var.sample_db_port}'",
      "echo 'External endpoint accessible from internet, internal endpoint from VPC only'"
    ]

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.redis_enterprise_nodes[0].public_ip
      timeout     = "10m"
    }
  }

  depends_on = [null_resource.redis_cluster_join]
}