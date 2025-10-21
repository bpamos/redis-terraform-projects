# =============================================================================
# REDIS CLOUD SUBSCRIPTION
# =============================================================================

# Get payment method for subscription billing
data "rediscloud_payment_method" "card" {
  card_type         = var.credit_card_type
  last_four_numbers = var.credit_card_last_four
}

# Create Redis Cloud subscription with VPC networking
resource "rediscloud_subscription" "redis" {
  name              = var.subscription_name
  payment_method    = "credit-card"
  payment_method_id = data.rediscloud_payment_method.card.id
  memory_storage    = var.memory_storage
  redis_version     = var.redis_version

  cloud_provider {
    provider         = var.cloud_provider
    cloud_account_id = var.cloud_account_id

    region {
      region                       = var.rediscloud_region
      multiple_availability_zones  = var.multi_az
      networking_deployment_cidr   = var.networking_deployment_cidr
      preferred_availability_zones = length(var.preferred_azs) > 0 ? var.preferred_azs : null
    }
  }

  creation_plan {
    dataset_size_in_gb           = var.dataset_size_in_gb
    quantity                     = var.database_quantity
    replication                  = var.replication
    throughput_measurement_by    = var.throughput_by
    throughput_measurement_value = var.throughput_value
    modules                      = var.modules
  }

  maintenance_windows {
    mode = "manual"
    window {
      start_hour        = var.maintenance_start_hour
      duration_in_hours = var.maintenance_duration
      days              = var.maintenance_days
    }
  }
}

# =============================================================================
# REDIS DATABASE
# =============================================================================

# Create Redis database within the subscription
resource "rediscloud_subscription_database" "db" {
  subscription_id              = rediscloud_subscription.redis.id
  name                         = var.database_name
  dataset_size_in_gb           = var.dataset_size_in_gb
  data_persistence             = var.data_persistence
  throughput_measurement_by    = var.throughput_by
  throughput_measurement_value = var.throughput_value
  replication                  = var.replication

  # Configure Redis modules
  modules = [for mod in var.modules : { name = mod }]

  # Set up database monitoring alerts (only if enabled)
  dynamic "alert" {
    for_each = var.enable_alerts ? [1] : []
    content {
      name  = "dataset-size"
      value = var.dataset_size_alert_threshold
    }
  }
  
  dynamic "alert" {
    for_each = var.enable_alerts ? [1] : []
    content {
      name  = "throughput-higher-than"
      value = var.throughput_value * (var.throughput_alert_threshold_percentage / 100)
    }
  }

  tags = var.tags
}
