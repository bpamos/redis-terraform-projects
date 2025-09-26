# =============================================================================
# REDIS ENTERPRISE LOAD BALANCER
# =============================================================================
# Conditional load balancer deployment - either NLB or HAProxy
# =============================================================================

# AWS Network Load Balancer implementation
module "nlb_load_balancer" {
  count  = var.load_balancer_type == "nlb" ? 1 : 0
  source = "./nlb"
  
  # Common parameters
  name_prefix         = var.name_prefix
  vpc_id              = var.vpc_id
  public_subnet_ids   = var.public_subnet_ids
  private_subnet_ids  = var.private_subnet_ids
  
  # Redis Enterprise instance information
  instance_ids    = var.instance_ids
  private_ips     = var.private_ips
  public_ips      = var.public_ips
  
  # Security and tagging
  allow_access_from = var.allow_access_from
  tags              = var.tags
}

# HAProxy on EC2 implementation
module "haproxy_load_balancer" {
  count  = var.load_balancer_type == "haproxy" ? 1 : 0
  source = "./haproxy"
  
  # Common parameters
  name_prefix         = var.name_prefix
  vpc_id              = var.vpc_id
  public_subnet_ids   = var.public_subnet_ids
  private_subnet_ids  = var.private_subnet_ids
  
  # Redis Enterprise instance information  
  instance_ids    = var.instance_ids
  private_ips     = var.private_ips
  public_ips      = var.public_ips
  
  # HAProxy specific configuration
  key_name             = var.key_name
  ssh_private_key_path = var.ssh_private_key_path
  platform             = var.platform
  instance_type        = var.haproxy_instance_type
  
  # Security and tagging
  allow_access_from = var.allow_access_from
  tags              = var.tags
}

# NGINX on EC2 implementation
module "nginx_load_balancer" {
  count  = var.load_balancer_type == "nginx" ? 1 : 0
  source = "./nginx"
  
  # Common parameters
  name_prefix         = var.name_prefix
  vpc_id              = var.vpc_id
  public_subnet_ids   = var.public_subnet_ids
  private_subnet_ids  = var.private_subnet_ids
  
  # Redis Enterprise instance information
  instance_ids    = var.instance_ids
  private_ips     = var.private_ips
  public_ips      = var.public_ips
  
  # NGINX specific configuration
  key_name             = var.key_name
  ssh_private_key_path = var.ssh_private_key_path
  platform             = var.platform
  instance_type        = var.nginx_instance_type
  nginx_instance_count = var.nginx_instance_count
  
  # Port configuration
  frontend_database_port = var.frontend_database_port
  backend_database_port  = var.backend_database_port
  frontend_api_port      = var.frontend_api_port
  backend_api_port       = var.backend_api_port
  frontend_ui_port       = var.frontend_ui_port
  backend_ui_port        = var.backend_ui_port
  additional_database_ports = var.additional_database_ports
  database_port_range_start = var.database_port_range_start
  database_port_range_end   = var.database_port_range_end
  
  # Load balancing methods
  database_lb_method = var.database_lb_method
  api_lb_method      = var.api_lb_method
  ui_lb_method       = var.ui_lb_method
  
  # Health check configuration
  max_fails         = var.max_fails
  fail_timeout      = var.fail_timeout
  proxy_timeout     = var.proxy_timeout
  
  # Security and tagging
  allow_access_from = var.allow_access_from
  tags              = var.tags
}