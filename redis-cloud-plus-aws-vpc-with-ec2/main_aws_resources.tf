# =============================================================================
# AWS RESOURCES
# All AWS infrastructure: VPC, EC2, Security Groups, and Observability Stack
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
# SECURITY GROUP FOR EC2
# =============================================================================

module "security_group" {
  count  = var.enable_ec2_testing ? 1 : 0
  source = "./modules/security_group"

  name_prefix     = var.name_prefix
  vpc_id          = module.vpc.vpc_id
  ssh_cidr_blocks = var.allow_ssh_from
  owner           = var.owner
  project         = var.project
}

# =============================================================================
# EC2 TEST INSTANCE
# =============================================================================

module "ec2_test" {
  count  = var.enable_ec2_testing ? 1 : 0
  source = "./modules/ec2_test"

  name_prefix          = var.name_prefix
  ec2_name_suffix      = var.ec2_name_suffix
  ami_id               = data.aws_ami.ubuntu.id
  instance_type        = var.ec2_instance_type
  subnet_id            = module.vpc.public_subnet_ids[0]
  security_group_id    = module.security_group[0].riot_ec2_sg_id
  key_name             = var.ec2_key_name
  ssh_private_key_path = var.ec2_ssh_private_key_path
  owner                = var.owner
  project              = var.project
  
  # Redis Cloud connection details
  redis_cloud_endpoint = module.redis_database_primary.database_private_endpoint
  redis_cloud_password = module.redis_database_primary.database_password

  depends_on = [
    module.redis_database_primary,
    module.security_group
  ]
}

# =============================================================================
# OBSERVABILITY - PROMETHEUS AND GRAFANA
# =============================================================================

module "observability" {
  count  = var.enable_ec2_testing && var.enable_observability ? 1 : 0
  source = "./modules/observability"

  redis_cloud_endpoint   = module.redis_database_primary.database_private_endpoint
  instance_id            = module.ec2_test[0].instance_id
  instance_public_ip     = module.ec2_test[0].public_ip
  ssh_private_key_path   = var.ec2_ssh_private_key_path

  depends_on_resources = [
    module.ec2_test[0],
    module.rediscloud_peering
  ]

  tags = local.common_tags
}