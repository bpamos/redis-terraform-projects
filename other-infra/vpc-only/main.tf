# =============================================================================
# VPC-ONLY TERRAFORM PROJECT
# Creates AWS VPC infrastructure for Redis migration projects
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