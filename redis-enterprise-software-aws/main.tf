# =============================================================================
# REDIS ENTERPRISE SOFTWARE AWS DEPLOYMENT
# =============================================================================
# This configuration deploys a 3-node Redis Enterprise Software cluster on AWS
# =============================================================================

# Data sources for availability zones and AMI
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "rhel" {
  most_recent = true
  owners      = ["309956199498"] # Red Hat

  filter {
    name   = "name"
    values = ["RHEL-9*_HVM-*-x86_64-*-Hourly2-GP3"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Platform-specific AMI selection
locals {
  ami_id = var.platform == "ubuntu" ? data.aws_ami.ubuntu.id : data.aws_ami.rhel.id
}

# =============================================================================
# VPC INFRASTRUCTURE
# =============================================================================

module "vpc" {
  source = "./modules/vpc"

  name_prefix           = var.name_prefix
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = slice(data.aws_availability_zones.available.names, 0, length(var.public_subnet_cidrs))
  
  owner   = var.owner
  project = var.project

  tags = var.tags
}

# =============================================================================
# SECURITY GROUPS
# =============================================================================

module "security_group" {
  source = "./modules/security_group"

  name_prefix    = var.name_prefix
  vpc_id         = module.vpc.vpc_id
  allow_ssh_from = var.allow_ssh_from
  
  owner   = var.owner
  project = var.project

  tags = var.tags
}

# =============================================================================
# REDIS ENTERPRISE CLUSTER NODES
# =============================================================================

module "redis_enterprise_cluster" {
  source = "./modules/redis_enterprise_cluster"

  name_prefix         = var.name_prefix
  node_count          = var.node_count
  instance_type       = var.instance_type
  ami_id              = local.ami_id
  key_name            = var.key_name
  ssh_private_key_path = var.ssh_private_key_path
  
  # Network configuration
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.security_group.redis_enterprise_sg_id
  
  # Storage configuration
  node_root_size         = var.node_root_size
  data_volume_size       = var.data_volume_size
  data_volume_type       = var.data_volume_type
  persistent_volume_size = var.persistent_volume_size
  persistent_volume_type = var.persistent_volume_type
  ebs_encryption_enabled = var.ebs_encryption_enabled
  
  # Redis Enterprise configuration
  platform            = var.platform
  re_download_url     = var.re_download_url
  cluster_username    = var.cluster_username
  cluster_password    = var.cluster_password
  cluster_fqdn        = var.cluster_fqdn
  dns_hosted_zone_id  = var.dns_hosted_zone_id
  flash_enabled       = var.flash_enabled
  rack_awareness      = var.rack_awareness
  
  # Database configuration
  create_sample_database = var.create_sample_database
  sample_db_name        = var.sample_db_name
  sample_db_port        = var.sample_db_port
  sample_db_memory      = var.sample_db_memory
  
  owner   = var.owner
  project = var.project

  tags = var.tags
}

# =============================================================================
# DNS CONFIGURATION
# =============================================================================

module "dns" {
  source = "./modules/dns"

  dns_hosted_zone_id = var.dns_hosted_zone_id
  cluster_fqdn       = var.cluster_fqdn
  create_dns_records = var.create_dns_records
  
  # Node configuration
  node_count  = var.node_count
  public_ips  = module.redis_enterprise_cluster.public_ips
  private_ips = module.redis_enterprise_cluster.private_ips
  
  name_prefix = var.name_prefix
  owner       = var.owner
  project     = var.project
  tags        = var.tags
}