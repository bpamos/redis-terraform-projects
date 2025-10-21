# =============================================================================
# REDIS CLOUD SUBSCRIPTION MODULE
# Creates a Redis Cloud subscription with VPC networking
# =============================================================================

# Get payment method for subscription billing (only for credit card)
data "rediscloud_payment_method" "card" {
  count             = var.payment_method == "credit-card" ? 1 : 0
  card_type         = var.credit_card_type
  last_four_numbers = var.credit_card_last_four
}

# Create Redis Cloud subscription with VPC networking
resource "rediscloud_subscription" "redis" {
  name              = var.subscription_name
  payment_method    = var.payment_method
  payment_method_id = var.payment_method == "credit-card" ? data.rediscloud_payment_method.card[0].id : null
  memory_storage    = var.memory_storage

  # Allowlist configuration (only when using your own cloud account)
  dynamic "allowlist" {
    for_each = var.allowlist_security_group_ids != null || var.allowlist_cidrs != null ? [1] : []
    content {
      security_group_ids = var.allowlist_security_group_ids
      cidrs              = var.allowlist_cidrs
    }
  }

  # Customer managed key resource
  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key_resource_name != null ? [1] : []
    content {
      resource_name = var.customer_managed_key_resource_name
    }
  }

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