# =============================================================================
# REDIS CLOUD RESOURCES
# All Redis Cloud subscription, database, and peering configuration
# =============================================================================

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

  # Advanced subscription configuration
  allowlist_security_group_ids   = var.allowlist_security_group_ids
  allowlist_cidrs                = var.allowlist_cidrs
  customer_managed_key_resource_name = var.customer_managed_key_resource_name
}

# =============================================================================
# REDIS CLOUD DATABASES
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
  redis_version      = var.redis_version

  # Alerting configuration
  enable_alerts                = var.enable_alerts
  dataset_size_alert_threshold = var.dataset_size_alert_threshold

  # Advanced database configuration
  protocol                                = var.protocol
  support_oss_cluster_api                 = var.support_oss_cluster_api
  resp_version                            = var.resp_version
  external_endpoint_for_oss_cluster_api   = var.external_endpoint_for_oss_cluster_api
  enable_tls                              = var.enable_tls
  client_ssl_certificate                  = var.client_ssl_certificate
  client_tls_certificates                 = var.client_tls_certificates
  replica_of                              = var.replica_of
  data_eviction                           = var.data_eviction
  password                                = var.password
  average_item_size_in_bytes              = var.average_item_size_in_bytes
  source_ips                              = var.source_ips
  hashing_policy                          = var.hashing_policy
  port                                    = var.port
  enable_default_user                     = var.enable_default_user
  remote_backup_interval                  = var.remote_backup_interval
  remote_backup_time_utc                  = var.remote_backup_time_utc
  remote_backup_storage_type              = var.remote_backup_storage_type
  remote_backup_storage_path              = var.remote_backup_storage_path

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
  route_table_id  = module.vpc.public_route_table_id
  peer_cidr_block = var.peer_cidr_block

  depends_on = [
    module.redis_subscription,
    module.redis_database_primary
  ]
}