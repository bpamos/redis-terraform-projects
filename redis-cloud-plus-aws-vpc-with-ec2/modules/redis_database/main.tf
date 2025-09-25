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


  # Redis Cloud requires lowercase tag keys
  tags = {
    for k, v in var.tags : lower(k) => v
  }
}