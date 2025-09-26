# =============================================================================
# REDIS ENTERPRISE SOFTWARE AWS DEPLOYMENT - MODULAR ARCHITECTURE
# =============================================================================
# Professional modular deployment of Redis Enterprise Software cluster on AWS
# Separates concerns: Infrastructure -> Platform -> Application
# =============================================================================

# Data sources for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Load balancer deployment (conditional: NLB or HAProxy)

# =============================================================================
# INFRASTRUCTURE LAYER - VPC AND NETWORKING
# =============================================================================

module "vpc" {
  source = "./modules/network/vpc"

  name_prefix           = var.name_prefix
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = slice(data.aws_availability_zones.available.names, 0, length(var.public_subnet_cidrs))
  
  owner   = var.owner
  project = var.project
  tags    = var.tags
}

module "security_group" {
  source = "./modules/network/security_groups"

  name_prefix    = var.name_prefix
  vpc_id         = module.vpc.vpc_id
  allow_ssh_from = var.allow_ssh_from
  
  owner   = var.owner
  project = var.project
  tags    = var.tags
}

module "load_balancer" {
  source = "./modules/infrastructure/load_balancer"

  load_balancer_type = var.load_balancer_type
  name_prefix        = var.name_prefix
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  
  # Redis Enterprise instance information
  instance_ids = module.redis_instances.instance_ids
  private_ips  = module.redis_instances.private_ips
  public_ips   = module.redis_instances.public_ips
  
  # HAProxy/NGINX specific configuration (only used when load_balancer_type = "haproxy" or "nginx")
  key_name               = var.key_name
  ssh_private_key_path   = var.ssh_private_key_path
  platform               = var.platform
  haproxy_instance_type  = "t3.medium"
  
  # NGINX specific configuration (only used when load_balancer_type = "nginx")
  nginx_instance_type       = var.nginx_instance_type
  nginx_instance_count      = var.nginx_instance_count
  frontend_database_port    = var.frontend_database_port
  backend_database_port     = var.backend_database_port
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
  
  # Dependencies - wait for instances to be ready
  depends_on = [module.redis_instances]
}

# =============================================================================
# PLATFORM LAYER - AMI SELECTION AND USER DATA
# =============================================================================

module "ami_selection" {
  source = "./modules/platform/ami_selection"
  
  platform = var.platform
}

module "user_data" {
  source = "./modules/platform/user_data"
  
  platform = var.platform
  hostname = "${var.name_prefix}-redis-node"
}

# =============================================================================
# COMPUTE LAYER - EC2 INSTANCES AND STORAGE
# =============================================================================

module "redis_instances" {
  source = "./modules/compute/redis_instances"

  name_prefix  = var.name_prefix
  node_count   = var.node_count
  instance_type = var.instance_type
  ami_id       = module.ami_selection.ami_id
  key_name     = var.key_name
  
  # Network configuration
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.security_group.redis_enterprise_sg_id
  
  # Storage configuration
  node_root_size         = var.node_root_size
  ebs_encryption_enabled = var.ebs_encryption_enabled
  associate_public_ip_address = true
  
  # Platform configuration
  user_data_base64 = module.user_data.user_data_base64
  
  owner   = var.owner
  project = var.project
  tags    = var.tags
}

module "storage" {
  source = "./modules/compute/storage"

  name_prefix = var.name_prefix
  node_count  = var.node_count
  subnet_ids  = module.vpc.public_subnet_ids
  
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
  source = "./modules/application/redis_enterprise_install"

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
  source = "./modules/application/cluster_bootstrap"

  name_prefix          = var.name_prefix
  node_count           = var.node_count
  platform             = var.platform
  ssh_private_key_path = var.ssh_private_key_path
  cluster_fqdn         = "${var.name_prefix}-cluster"
  
  # Cluster configuration
  cluster_username = var.cluster_username
  cluster_password = var.cluster_password
  rack_awareness   = var.rack_awareness
  flash_enabled    = var.flash_enabled
  
  # Instance information
  instance_ids        = module.redis_instances.instance_ids
  public_ips          = module.redis_instances.public_ips
  private_ips         = module.redis_instances.private_ips
  availability_zones  = module.redis_instances.availability_zones
  
  # Dependencies - wait for installation to complete
  installation_completion_ids = module.redis_enterprise_install.installation_completion_ids
}

module "database_management" {
  source = "./modules/application/database_management"

  name_prefix          = var.name_prefix
  platform             = var.platform
  ssh_private_key_path = var.ssh_private_key_path
  cluster_fqdn         = "${var.name_prefix}-cluster"
  
  # Instance information
  public_ips = module.redis_instances.public_ips
  
  # Cluster credentials
  cluster_username = var.cluster_username
  cluster_password = var.cluster_password
  
  # Database configuration
  create_sample_database = var.create_sample_database
  sample_db_name        = var.sample_db_name
  sample_db_port        = var.sample_db_port
  sample_db_memory      = var.sample_db_memory
  
  # Dependencies - wait for cluster bootstrap and load balancer config to complete
  cluster_verification_id = module.cluster_bootstrap.cluster_verification
  load_balancer_config_id = module.cluster_bootstrap.load_balancer_config
}