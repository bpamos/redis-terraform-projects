# =============================================================================
# REDIS CLOUD + RIOT TERRAFORM PROJECT  
# Creates Redis Cloud subscription, AWS VPC, and RIOT tooling for migration
# =============================================================================

# Get available AZs in current region
data "aws_availability_zones" "available" {
  state = "available"
}

# Get latest Ubuntu 22.04 LTS AMI
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

module "security_group" {
  source = "./modules/security_group"
  
  name_prefix       = var.name_prefix
  vpc_id            = module.vpc.vpc_id
  owner             = var.owner
  project           = var.project
  ssh_cidr_blocks   = var.allow_ssh_from
}

# =============================================================================
# REDIS CLOUD
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

# VPC Peering between AWS VPC and Redis Cloud
module "rediscloud_peering" {
  source = "./modules/rediscloud_peering"
  
  subscription_id = module.rediscloud.rediscloud_subscription_id
  aws_account_id  = var.aws_account_id
  region          = var.rediscloud_region
  vpc_id          = module.vpc.vpc_id
  vpc_cidr        = var.vpc_cidr
  route_table_id  = module.vpc.route_table_id
  peer_cidr_block = var.peer_cidr_block

  depends_on = [
    module.rediscloud
  ]
}

# =============================================================================
# RIOT TOOLING
# =============================================================================

# RIOT EC2 instance for replication tools
module "ec2_riot" {
  source = "./modules/ec2_riot"
  
  name_prefix          = var.name_prefix
  owner                = var.owner
  project              = var.project
  ami_id               = data.aws_ami.ubuntu.id
  instance_type        = var.riot_instance_type
  subnet_id            = module.vpc.public_subnet_ids[0] # Public subnet for access
  security_group_id    = module.security_group.riot_ec2_sg_id
  key_name             = var.key_name
  ssh_private_key_path = var.ssh_private_key_path
}