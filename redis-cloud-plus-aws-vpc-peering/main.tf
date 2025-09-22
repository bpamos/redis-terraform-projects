# =============================================================================
# REDIS CLOUD + VPC TERRAFORM PROJECT  
# Creates Redis Cloud subscription, AWS VPC, and VPC peering (no RIOT)
# =============================================================================

# Get available AZs in current region
data "aws_availability_zones" "available" {
  state = "available"
}


# Common tags for all resources
locals {
  common_tags = merge({
    Owner     = var.owner
    Project   = var.project
    ManagedBy = "terraform"
  }, var.tags)
}

# =============================================================================
# VPC INFRASTRUCTURE
# =============================================================================

module "vpc" {
  source = "./modules/vpc"

  name_prefix          = var.name_prefix
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 2)
  owner                = var.owner
  project              = var.project
}


# =============================================================================
# REDIS CLOUD SUBSCRIPTION
# =============================================================================

# Create Redis Cloud subscription
module "redis_subscription" {
  source = "./modules/redis_subscription"

  # Provider configuration
  rediscloud_api_key    = var.rediscloud_api_key
  rediscloud_secret_key = var.rediscloud_secret_key

  # Subscription configuration
  subscription_name = var.subscription_name
  memory_storage    = var.memory_storage
  redis_version     = var.redis_version

  # Cloud provider configuration
  cloud_provider             = var.cloud_provider
  cloud_account_id           = var.cloud_account_id
  rediscloud_region          = var.rediscloud_region
  multi_az                   = var.multi_az
  networking_deployment_cidr = var.networking_deployment_cidr
  preferred_azs              = var.preferred_azs

  # Payment configuration
  payment_method        = var.payment_method
  credit_card_type      = var.credit_card_type
  credit_card_last_four = var.credit_card_last_four

  # Initial creation plan (required for subscription creation)
  initial_dataset_size_in_gb = var.initial_dataset_size_in_gb
  initial_database_quantity  = var.initial_database_quantity
  initial_replication        = var.initial_replication
  initial_throughput_by      = var.initial_throughput_by
  initial_throughput_value   = var.initial_throughput_value
  initial_modules            = var.initial_modules

  # Maintenance configuration
  maintenance_start_hour = var.maintenance_start_hour
  maintenance_duration   = var.maintenance_duration
  maintenance_days       = var.maintenance_days
}

# =============================================================================
# REDIS CLOUD DATABASE
# =============================================================================

# Primary application database
module "redis_database_primary" {
  source = "./modules/redis_database"

  subscription_id    = module.redis_subscription.subscription_id
  database_name      = var.database_name
  dataset_size_in_gb = var.dataset_size_in_gb
  data_persistence   = var.data_persistence
  throughput_by      = var.throughput_by
  throughput_value   = var.throughput_value
  replication        = var.replication
  modules            = var.modules_enabled

  # Alerting configuration
  enable_alerts                = var.enable_alerts
  dataset_size_alert_threshold = var.dataset_size_alert_threshold

  tags = merge(local.common_tags, {
    database_type = "primary"
    application   = "main"
  })
}

# =============================================================================
# VPC PEERING
# =============================================================================

# VPC Peering between AWS VPC and Redis Cloud
module "rediscloud_peering" {
  source = "./modules/rediscloud_peering"

  subscription_id = module.redis_subscription.subscription_id
  aws_account_id  = var.aws_account_id
  region          = var.rediscloud_region
  vpc_id          = module.vpc.vpc_id
  vpc_cidr        = var.vpc_cidr
  route_table_id  = module.vpc.private_route_table_ids[0]
  peer_cidr_block = var.peer_cidr_block

  depends_on = [
    module.redis_subscription,
    module.redis_database_primary
  ]
}

