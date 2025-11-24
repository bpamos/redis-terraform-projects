# =============================================================================
# SINGLE REGION REDIS ENTERPRISE CLUSTER
# =============================================================================
# Wrapper module that deploys a complete Redis Enterprise cluster in one region
# Used by the multi-region orchestration layer
# =============================================================================

# Data sources for availability zones in this region
data "aws_availability_zones" "available" {
  state = "available"
}

# Local values
locals {
  # Name prefix includes region for uniqueness
  name_prefix = "${var.user_prefix}-${var.cluster_name}-${var.region}"

  # Cluster FQDN for this region (must match name_prefix for DNS consistency)
  cluster_fqdn = "${var.user_prefix}-${var.cluster_name}-${var.region}"

  # Use specified AZs if provided, otherwise auto-select
  selected_azs = length(var.region_config.availability_zones) > 0 ? var.region_config.availability_zones : slice(data.aws_availability_zones.available.names, 0, 3)

  # Subnet CIDRs from region config or defaults
  public_subnet_cidrs  = var.region_config.public_subnet_cidrs
  private_subnet_cidrs = var.region_config.private_subnet_cidrs
}

# =============================================================================
# INFRASTRUCTURE LAYER - VPC AND NETWORKING
# =============================================================================

module "vpc" {
  source = "../vpc"


  name_prefix          = local.name_prefix
  vpc_cidr             = var.region_config.vpc_cidr
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
  azs                  = local.selected_azs

  owner   = var.owner
  project = var.project
  tags    = var.tags
}

module "security_group" {
  source = "../security_groups"


  name_prefix       = local.name_prefix
  vpc_id            = module.vpc.vpc_id
  allow_ssh_from    = var.allow_ssh_from
  peer_region_cidrs = var.peer_region_cidrs

  owner   = var.owner
  project = var.project
  tags    = var.tags
}

module "dns" {
  source = "../dns"


  dns_hosted_zone_id = var.dns_hosted_zone_id
  cluster_fqdn       = local.cluster_fqdn
  create_dns_records = var.create_dns_records

  # Instance information
  node_count  = var.node_count
  public_ips  = module.redis_instances.public_ips
  private_ips = module.redis_instances.private_ips

  name_prefix = local.name_prefix
  owner       = var.owner
  project     = var.project
  tags        = var.tags
}

# =============================================================================
# PLATFORM LAYER - USER DATA
# =============================================================================

module "user_data" {
  source = "../user_data"

  platform = var.platform
  hostname = "${var.user_prefix}-${var.cluster_name}-${var.region}-node"
}

# =============================================================================
# COMPUTE LAYER - EC2 INSTANCES AND STORAGE
# =============================================================================

module "redis_instances" {
  source = "../redis_instances"


  name_prefix   = local.name_prefix
  user_prefix   = var.user_prefix
  cluster_name  = "${var.cluster_name}-${var.region}"
  node_count    = var.node_count
  instance_type = var.instance_type
  platform      = var.platform
  key_name      = var.region_config.key_name

  # Use PUBLIC subnets (matching original deployment)
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.security_group.redis_enterprise_sg_id

  # Storage configuration
  node_root_size              = var.node_root_size
  ebs_encryption_enabled      = var.ebs_encryption_enabled
  associate_public_ip_address = var.associate_public_ip_address
  use_elastic_ips             = var.use_elastic_ips

  # Platform configuration
  user_data_base64 = module.user_data.user_data_base64

  owner   = var.owner
  project = var.project
  tags    = var.tags
}

module "storage" {
  source = "../storage"


  name_prefix  = local.name_prefix
  user_prefix  = var.user_prefix
  cluster_name = "${var.cluster_name}-${var.region}"
  node_count   = var.node_count
  subnet_ids   = module.vpc.public_subnet_ids  # Matching original deployment

  # Instance dependencies
  instance_ids = module.redis_instances.instance_ids

  # Storage configuration
  data_volume_size       = var.data_volume_size
  data_volume_type       = var.data_volume_type
  persistent_volume_size = var.persistent_volume_size
  persistent_volume_type = var.persistent_volume_type
  ebs_encryption_enabled = var.ebs_encryption_enabled

  owner   = var.owner
  project = var.project
  tags    = var.tags
}

# =============================================================================
# APPLICATION LAYER - REDIS ENTERPRISE SOFTWARE AND CLUSTER
# =============================================================================

module "redis_enterprise_install" {
  source = "../redis_enterprise_install"


  node_count           = var.node_count
  platform             = var.platform
  re_download_url      = var.re_download_url
  ssh_private_key_path = var.region_config.ssh_key_path

  # Instance information
  instance_ids = module.redis_instances.instance_ids
  public_ips   = module.redis_instances.public_ips  # Contains EIPs when enabled, or regular public IPs
  private_ips  = module.redis_instances.private_ips

  # Storage dependencies
  data_volume_attachment_ids       = module.storage.data_volume_attachment_ids
  persistent_volume_attachment_ids = module.storage.persistent_volume_attachment_ids
}

module "cluster_bootstrap" {
  source = "../cluster_bootstrap"


  name_prefix          = local.name_prefix
  node_count           = var.node_count
  platform             = var.platform
  ssh_private_key_path = var.region_config.ssh_key_path
  hosted_zone_name     = var.hosted_zone_name

  # Cluster configuration
  cluster_username = var.cluster_username
  cluster_password = var.cluster_password
  rack_awareness   = var.rack_awareness
  flash_enabled    = var.flash_enabled

  # Instance information
  instance_ids       = module.redis_instances.instance_ids
  public_ips         = module.redis_instances.public_ips  # Contains EIPs when enabled
  private_ips        = module.redis_instances.private_ips
  availability_zones = module.redis_instances.availability_zones

  # Dependencies
  installation_completion_ids = module.redis_enterprise_install.installation_completion_ids
}

module "database_management" {
  source = "../database_management"


  name_prefix          = local.name_prefix
  platform             = var.platform
  ssh_private_key_path = var.region_config.ssh_key_path
  hosted_zone_name     = var.hosted_zone_name

  # Instance information
  public_ips = module.redis_instances.public_ips  # Contains EIPs when enabled, or regular public IPs

  # Cluster credentials
  cluster_username = var.cluster_username
  cluster_password = var.cluster_password

  # Database configuration
  create_sample_database = var.create_sample_database
  sample_db_name         = var.sample_db_name
  sample_db_port         = var.sample_db_port
  sample_db_memory       = var.sample_db_memory

  # Dependencies
  cluster_verification_id = module.cluster_bootstrap.cluster_verification
}

# =============================================================================
# TEST NODE (OPTIONAL)
# =============================================================================

module "test_node" {
  count  = var.enable_test_node ? 1 : 0
  source = "../test_node"

  name_prefix          = local.name_prefix
  instance_type        = var.test_node_instance_type
  subnet_id            = module.vpc.public_subnet_ids[0]
  security_group_id    = module.security_group.test_node_sg_id
  key_name             = var.region_config.key_name
  ssh_private_key_path = var.region_config.ssh_key_path

  # Optional: Pass database endpoint for automatic testing
  redis_endpoint = var.create_sample_database ? "${var.sample_db_name}-${var.sample_db_port}.${local.cluster_fqdn}.${var.hosted_zone_name}" : ""
  redis_password = ""  # Redis Enterprise databases typically don't have passwords by default

  owner   = var.owner
  project = var.project
  tags    = var.tags

  depends_on = [
    module.cluster_bootstrap,
    module.database_management
  ]
}
