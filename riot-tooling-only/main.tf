# =============================================================================
# RIOT TOOLING-ONLY TERRAFORM PROJECT
# Creates AWS VPC and EC2 instance with RIOT-X tools for Redis migration
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
# RIOT TOOLING EC2 INSTANCE
# =============================================================================

# RIOT EC2 instance for migration tools
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