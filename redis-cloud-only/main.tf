# =============================================================================
# REDIS CLOUD-ONLY TERRAFORM PROJECT
# Creates Redis Cloud subscription and database
# =============================================================================

# Common tags for all resources
locals {
  common_tags = {
    Owner       = var.owner
    Project     = var.project
    Environment = "demo"
    ManagedBy   = "terraform"
  }
}

# =============================================================================
# REDIS CLOUD INFRASTRUCTURE
# =============================================================================

# Redis Cloud database and subscription
module "rediscloud" {
  source = "./modules/rediscloud"

  rediscloud_api_key         = var.rediscloud_api_key
  rediscloud_secret_key      = var.rediscloud_secret_key
  subscription_name          = var.subscription_name
  rediscloud_region          = var.rediscloud_region
  cloud_provider             = var.cloud_provider
  networking_deployment_cidr = var.networking_deployment_cidr
  preferred_azs              = var.preferred_azs
  credit_card_type           = var.credit_card_type
  credit_card_last_four      = var.credit_card_last_four
  redis_version              = var.redis_version
  memory_storage             = var.memory_storage
  cloud_account_id           = var.cloud_account_id
  dataset_size_in_gb         = var.dataset_size_in_gb
  throughput_value           = var.throughput_value
  modules                    = var.modules_enabled
  multi_az                   = var.multi_az
  database_quantity          = var.database_quantity
  replication                = var.replication
  throughput_by              = var.throughput_by
  maintenance_start_hour     = var.maintenance_start_hour
  maintenance_duration       = var.maintenance_duration
  maintenance_days           = var.maintenance_days
  database_name              = var.database_name
  data_persistence           = var.data_persistence
  enable_alerts              = var.enable_alerts
  dataset_size_alert_threshold = var.dataset_size_alert_threshold
  throughput_alert_threshold_percentage = var.throughput_alert_threshold_percentage
  tags                       = var.tags
}