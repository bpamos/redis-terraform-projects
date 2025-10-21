# =============================================================================
# REDIS DATABASE MODULE
# Creates individual Redis databases within a subscription
# =============================================================================

# Create Redis database within the subscription
resource "rediscloud_subscription_database" "db" {
  subscription_id              = var.subscription_id
  name                         = var.database_name
  dataset_size_in_gb           = var.dataset_size_in_gb
  data_persistence             = var.data_persistence
  throughput_measurement_by    = var.throughput_by
  throughput_measurement_value = var.throughput_value
  replication                  = var.replication
  redis_version                = var.redis_version

  # Advanced database configuration
  protocol                                = var.protocol
  support_oss_cluster_api                 = var.support_oss_cluster_api
  resp_version                            = var.resp_version
  external_endpoint_for_oss_cluster_api   = var.external_endpoint_for_oss_cluster_api
  data_eviction                           = var.data_eviction
  password                                = var.password
  average_item_size_in_bytes              = var.average_item_size_in_bytes
  port                                    = var.port
  enable_default_user                     = var.enable_default_user

  # TLS/SSL configuration
  enable_tls              = var.enable_tls
  client_ssl_certificate  = var.client_ssl_certificate
  client_tls_certificates = var.client_tls_certificates

  # Network security
  source_ips      = var.source_ips
  hashing_policy  = var.hashing_policy
  replica_of      = var.replica_of

  # Configure Redis modules
  dynamic "modules" {
    for_each = var.modules
    content {
      name = modules.value
    }
  }

  # Set up database monitoring alerts (only if enabled)
  dynamic "alert" {
    for_each = var.enable_alerts ? [1] : []
    content {
      name  = "dataset-size"
      value = var.dataset_size_alert_threshold
    }
  }

  # Remote backup configuration
  dynamic "remote_backup" {
    for_each = var.remote_backup_interval != null ? [1] : []
    content {
      interval        = var.remote_backup_interval
      time_utc        = var.remote_backup_time_utc
      storage_type    = var.remote_backup_storage_type
      storage_path    = var.remote_backup_storage_path
    }
  }

  # Redis Cloud requires lowercase tag keys
  tags = {
    for k, v in var.tags : lower(k) => v
  }
}