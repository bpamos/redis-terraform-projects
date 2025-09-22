# =============================================================================
# REDIS CLOUD SUBSCRIPTION MODULE
# Creates a Redis Cloud subscription with VPC networking
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
    dataset_size_in_gb           = var.initial_dataset_size_in_gb
    quantity                     = var.initial_database_quantity
    replication                  = var.initial_replication
    throughput_measurement_by    = var.initial_throughput_by
    throughput_measurement_value = var.initial_throughput_value
    modules                      = var.initial_modules
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