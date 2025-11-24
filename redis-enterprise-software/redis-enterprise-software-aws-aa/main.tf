# =============================================================================
# REDIS ENTERPRISE ACTIVE-ACTIVE (MULTI-REGION) DEPLOYMENT
# =============================================================================
# Deploys Redis Enterprise Software clusters across multiple AWS regions
# with VPC peering mesh and automated CRDB (Active-Active) database creation
# =============================================================================

# Get hosted zone information for DNS
data "aws_route53_zone" "main" {
  zone_id = var.dns_hosted_zone_id
}

# Local values for configuration
locals {
  # Name prefix for all resources
  name_prefix = "${var.user_prefix}-${var.cluster_name}"

  # Get list of regions
  region_list = keys(var.regions)

  # Generate peer region CIDRs for each region (all other regions' CIDRs)
  peer_region_cidrs = {
    for region, config in var.regions : region => [
      for peer_region, peer_config in var.regions :
      peer_config.vpc_cidr
      if peer_region != region
    ]
  }
}

# Configure AWS providers for each region
provider "aws" {
  region = local.region_list[0]
  alias  = "region1"
}

provider "aws" {
  region = length(local.region_list) > 1 ? local.region_list[1] : local.region_list[0]
  alias  = "region2"
}

# =============================================================================
# REGION 1 CLUSTER
# =============================================================================

module "redis_cluster_region1" {
  source = "./modules/single_region"

  providers = {
    aws = aws.region1
  }

  # Region-specific configuration
  region        = local.region_list[0]
  region_config = var.regions[local.region_list[0]]

  # Global configuration
  user_prefix          = var.user_prefix
  cluster_name         = var.cluster_name
  owner                = var.owner
  project              = var.project
  tags                 = var.tags

  # DNS configuration (regional FQDNs)
  dns_hosted_zone_id   = var.dns_hosted_zone_id
  hosted_zone_name     = data.aws_route53_zone.main.name
  create_dns_records   = var.create_dns_records

  # Redis Enterprise configuration
  platform             = var.platform
  node_count           = var.node_count_per_region
  instance_type        = var.instance_type
  re_download_url      = var.re_download_url
  cluster_username     = var.cluster_username
  cluster_password     = var.cluster_password
  rack_awareness       = var.rack_awareness
  flash_enabled        = var.flash_enabled

  # Database configuration
  create_sample_database = var.create_sample_database
  sample_db_name         = var.sample_db_name
  sample_db_port         = var.sample_db_port
  sample_db_memory       = var.sample_db_memory

  # Storage configuration
  node_root_size         = var.node_root_size
  data_volume_size       = var.data_volume_size
  data_volume_type       = var.data_volume_type
  persistent_volume_size = var.persistent_volume_size
  persistent_volume_type = var.persistent_volume_type
  ebs_encryption_enabled = var.ebs_encryption_enabled

  # Network configuration
  associate_public_ip_address = var.associate_public_ip_address
  use_elastic_ips             = var.use_elastic_ips

  # Cross-region communication
  peer_region_cidrs = local.peer_region_cidrs[local.region_list[0]]
  allow_ssh_from    = var.allow_ssh_from

  # Test node configuration
  enable_test_node        = var.enable_test_nodes
  test_node_instance_type = var.test_node_instance_type
}

# =============================================================================
# REGION 2 CLUSTER
# =============================================================================

module "redis_cluster_region2" {
  count  = length(local.region_list) > 1 ? 1 : 0
  source = "./modules/single_region"

  providers = {
    aws = aws.region2
  }

  # Region-specific configuration
  region        = local.region_list[1]
  region_config = var.regions[local.region_list[1]]

  # Global configuration
  user_prefix          = var.user_prefix
  cluster_name         = var.cluster_name
  owner                = var.owner
  project              = var.project
  tags                 = var.tags

  # DNS configuration (regional FQDNs)
  dns_hosted_zone_id   = var.dns_hosted_zone_id
  hosted_zone_name     = data.aws_route53_zone.main.name
  create_dns_records   = var.create_dns_records

  # Redis Enterprise configuration
  platform             = var.platform
  node_count           = var.node_count_per_region
  instance_type        = var.instance_type
  re_download_url      = var.re_download_url
  cluster_username     = var.cluster_username
  cluster_password     = var.cluster_password
  rack_awareness       = var.rack_awareness
  flash_enabled        = var.flash_enabled

  # Database configuration
  create_sample_database = var.create_sample_database
  sample_db_name         = var.sample_db_name
  sample_db_port         = var.sample_db_port
  sample_db_memory       = var.sample_db_memory

  # Storage configuration
  node_root_size         = var.node_root_size
  data_volume_size       = var.data_volume_size
  data_volume_type       = var.data_volume_type
  persistent_volume_size = var.persistent_volume_size
  persistent_volume_type = var.persistent_volume_type
  ebs_encryption_enabled = var.ebs_encryption_enabled

  # Network configuration
  associate_public_ip_address = var.associate_public_ip_address
  use_elastic_ips             = var.use_elastic_ips

  # Cross-region communication
  peer_region_cidrs = local.peer_region_cidrs[local.region_list[1]]
  allow_ssh_from    = var.allow_ssh_from

  # Test node configuration
  enable_test_node        = var.enable_test_nodes
  test_node_instance_type = var.test_node_instance_type
}

# =============================================================================
# VPC PEERING MESH
# =============================================================================

# Create VPC peering connections between all regions
module "vpc_peering_mesh" {
  count  = length(local.region_list) > 1 ? 1 : 0
  source = "./modules/vpc_peering_mesh"

  providers = {
    aws.region1 = aws.region1
    aws.region2 = aws.region2
  }

  name_prefix = local.name_prefix

  # Pass VPC information from all clusters
  region_configs = merge(
    {
      (local.region_list[0]) = {
        vpc_id                 = module.redis_cluster_region1.vpc_id
        vpc_cidr               = var.regions[local.region_list[0]].vpc_cidr
        private_route_table_id = module.redis_cluster_region1.private_route_table_id
        public_route_table_id  = module.redis_cluster_region1.public_route_table_id
      }
    },
    length(local.region_list) > 1 ? {
      (local.region_list[1]) = {
        vpc_id                 = module.redis_cluster_region2[0].vpc_id
        vpc_cidr               = var.regions[local.region_list[1]].vpc_cidr
        private_route_table_id = module.redis_cluster_region2[0].private_route_table_id
        public_route_table_id  = module.redis_cluster_region2[0].public_route_table_id
      }
    } : {}
  )

  owner   = var.owner
  project = var.project
  tags    = var.tags

  # Ensure all clusters are created before peering
  depends_on = [module.redis_cluster_region1, module.redis_cluster_region2]
}

# =============================================================================
# ACTIVE-ACTIVE (CRDB) DATABASE
# =============================================================================

# Create Active-Active CRDB database across all regions
module "crdb" {
  count  = var.create_crdb_database && length(local.region_list) > 1 ? 1 : 0
  source = "./modules/crdb_management"

  providers = {
    aws = aws.region1
  }

  create_crdb  = var.create_crdb_database
  verify_crdb  = var.verify_crdb_creation

  # CRDB configuration
  crdb_name                = var.crdb_database_name
  crdb_port                = var.crdb_port
  crdb_memory_size         = var.crdb_memory_size
  enable_replication       = var.crdb_enable_replication
  enable_sharding          = var.crdb_enable_sharding
  shards_count             = var.crdb_shards_count
  enable_causal_consistency = var.crdb_enable_causal_consistency
  aof_policy               = var.crdb_aof_policy

  # Participating clusters
  participating_clusters = merge(
    {
      (local.region_list[0]) = {
        cluster_fqdn     = module.redis_cluster_region1.cluster_fqdn
        primary_node_ip  = module.redis_cluster_region1.public_ips[0]
      }
    },
    length(local.region_list) > 1 ? {
      (local.region_list[1]) = {
        cluster_fqdn     = module.redis_cluster_region2[0].cluster_fqdn
        primary_node_ip  = module.redis_cluster_region2[0].public_ips[0]
      }
    } : {}
  )

  # Cluster credentials
  cluster_username = var.cluster_username
  cluster_password = var.cluster_password

  # Wait for VPC peering and clusters to be fully ready
  depends_on = [
    module.redis_cluster_region1,
    module.redis_cluster_region2,
    module.vpc_peering_mesh
  ]
}
