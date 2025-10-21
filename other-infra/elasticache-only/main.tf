# =============================================================================
# ELASTICACHE-ONLY TERRAFORM PROJECT
# Creates AWS VPC and ElastiCache Redis infrastructure
# =============================================================================

# Get available AZs in current region
data "aws_availability_zones" "available" {
  state = "available"
}

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
# VPC INFRASTRUCTURE
# =============================================================================

module "vpc" {
  source = "./modules/vpc"
  
  name_prefix          = var.name_prefix
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = length(var.azs) > 0 ? var.azs : slice(data.aws_availability_zones.available.names, 0, 2)
  owner                = var.owner
  project              = var.project
}

# =============================================================================
# SECURITY GROUPS
# =============================================================================

module "security_group" {
  source = "./modules/security_group"
  
  name_prefix       = var.name_prefix
  vpc_id            = module.vpc.vpc_id
  owner             = var.owner
  project           = var.project
  ssh_cidr_blocks   = var.allow_ssh_from
}

# =============================================================================
# ELASTICACHE REDIS
# =============================================================================

# ElastiCache standalone with keyspace notifications (required for live replication)
module "elasticache_standalone_ksn" {
  source = "./modules/elasticache/standalone_ksn_enabled"
  
  name_prefix              = var.name_prefix
  replication_group_suffix = "standalone-ksn"
  subnet_ids               = module.vpc.private_subnet_ids
  security_group_id        = module.security_group.elasticache_sg_id
  node_type                = var.node_type
  replicas                 = var.standalone_replicas
  owner                    = var.owner
  project                  = var.project
}