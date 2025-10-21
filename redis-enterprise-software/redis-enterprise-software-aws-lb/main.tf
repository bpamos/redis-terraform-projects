# =============================================================================
# REDIS ENTERPRISE SOFTWARE AWS DEPLOYMENT - WITH LOAD BALANCER
# =============================================================================
# Professional modular deployment of Redis Enterprise Software cluster on AWS
# with integrated load balancer support (NLB, HAProxy, or NGINX)
# =============================================================================

# Data sources for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Local values for AZ selection logic
locals {
  # Use specified AZs if provided, otherwise auto-select based on subnet count
  selected_azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, length(var.public_subnet_cidrs))
}

# =============================================================================
# INFRASTRUCTURE LAYER - VPC AND NETWORKING
# =============================================================================

module "vpc" {
  source = "./modules/vpc"

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = local.selected_azs

  owner   = var.owner
  project = var.project
  tags    = var.tags
}

module "security_group" {
  source = "./modules/security_groups"

  name_prefix    = local.name_prefix
  vpc_id         = module.vpc.vpc_id
  allow_ssh_from = var.allow_ssh_from

  owner   = var.owner
  project = var.project
  tags    = var.tags
}

# =============================================================================
# PLATFORM LAYER - AMI SELECTION AND USER DATA
# =============================================================================

module "user_data" {
  source = "./modules/user_data"

  platform = var.platform
  hostname = "${var.user_prefix}-${var.cluster_name}-node"
}

# =============================================================================
# COMPUTE LAYER - EC2 INSTANCES AND STORAGE
# =============================================================================

module "redis_instances" {
  source = "./modules/redis_instances"

  name_prefix   = local.name_prefix
  user_prefix   = var.user_prefix
  cluster_name  = var.cluster_name
  node_count    = var.node_count
  instance_type = var.instance_type
  platform      = var.platform
  key_name      = var.key_name

  # Network configuration
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.security_group.redis_enterprise_sg_id

  # Storage configuration
  node_root_size              = var.node_root_size
  ebs_encryption_enabled      = var.ebs_encryption_enabled
  associate_public_ip_address = true
  use_elastic_ips             = var.use_elastic_ips

  # Platform configuration
  user_data_base64 = module.user_data.user_data_base64

  owner   = var.owner
  project = var.project
  tags    = var.tags
}

module "storage" {
  source = "./modules/storage"

  name_prefix  = local.name_prefix
  user_prefix  = var.user_prefix
  cluster_name = var.cluster_name
  node_count   = var.node_count
  subnet_ids   = module.vpc.public_subnet_ids

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
  source = "./modules/redis_enterprise_install"

  node_count           = var.node_count
  platform             = var.platform
  re_download_url      = var.re_download_url
  ssh_private_key_path = var.ssh_private_key_path

  # Instance information
  instance_ids = module.redis_instances.instance_ids
  public_ips   = module.redis_instances.public_ips
  private_ips  = module.redis_instances.private_ips

  # Storage dependencies - ensure volumes are attached before installation
  data_volume_attachment_ids       = module.storage.data_volume_attachment_ids
  persistent_volume_attachment_ids = module.storage.persistent_volume_attachment_ids
}

module "cluster_bootstrap" {
  source = "./modules/cluster_bootstrap"

  name_prefix          = local.name_prefix
  node_count           = var.node_count
  platform             = var.platform
  ssh_private_key_path = var.ssh_private_key_path
  hosted_zone_name     = "cluster.local" # Placeholder for LB version (no DNS used)

  # Cluster configuration
  cluster_username = var.cluster_username
  cluster_password = var.cluster_password
  rack_awareness   = var.rack_awareness
  flash_enabled    = var.flash_enabled

  # Instance information
  instance_ids       = module.redis_instances.instance_ids
  public_ips         = module.redis_instances.public_ips
  private_ips        = module.redis_instances.private_ips
  availability_zones = module.redis_instances.availability_zones

  # Dependencies - wait for installation to complete
  installation_completion_ids = module.redis_enterprise_install.installation_completion_ids
}

module "database_management" {
  source = "./modules/database_management"

  name_prefix          = local.name_prefix
  platform             = var.platform
  ssh_private_key_path = var.ssh_private_key_path
  hosted_zone_name     = "cluster.local" # Placeholder for LB version (no DNS used)

  # Instance information
  public_ips = module.redis_instances.public_ips

  # Cluster credentials
  cluster_username = var.cluster_username
  cluster_password = var.cluster_password

  # Database configuration
  create_sample_database = var.create_sample_database
  sample_db_name         = var.sample_db_name
  sample_db_port         = var.sample_db_port
  sample_db_memory       = var.sample_db_memory

  # Dependencies - wait for cluster bootstrap to complete
  cluster_verification_id = module.cluster_bootstrap.cluster_verification
}

# =============================================================================
# LOAD BALANCER LAYER - NLB, HAPROXY, OR NGINX
# =============================================================================

module "load_balancer" {
  source = "./modules/infrastructure/load_balancer"

  load_balancer_type = var.load_balancer_type
  name_prefix        = local.name_prefix
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  # Redis Enterprise instance information
  instance_ids = module.redis_instances.instance_ids
  private_ips  = module.redis_instances.private_ips
  public_ips   = module.redis_instances.public_ips

  # HAProxy/NGINX specific configuration (only used when load_balancer_type = "haproxy" or "nginx")
  key_name              = var.key_name
  ssh_private_key_path  = var.ssh_private_key_path
  platform              = var.platform
  haproxy_instance_type = var.haproxy_instance_type

  # NGINX specific configuration (only used when load_balancer_type = "nginx")
  nginx_instance_type       = var.nginx_instance_type
  nginx_instance_count      = var.nginx_instance_count
  frontend_api_port         = var.frontend_api_port
  backend_api_port          = var.backend_api_port
  frontend_ui_port          = var.frontend_ui_port
  backend_ui_port           = var.backend_ui_port
  additional_database_ports = var.additional_database_ports
  database_port_range_start = var.database_port_range_start
  database_port_range_end   = var.database_port_range_end
  database_lb_method        = var.database_lb_method
  api_lb_method             = var.api_lb_method
  ui_lb_method              = var.ui_lb_method
  max_fails                 = var.max_fails
  fail_timeout              = var.fail_timeout
  proxy_timeout             = var.proxy_timeout

  # Security and access
  allow_access_from = var.allow_ssh_from
  tags              = var.tags

  # Dependencies - wait for database management to complete
  depends_on = [module.database_management]
}
