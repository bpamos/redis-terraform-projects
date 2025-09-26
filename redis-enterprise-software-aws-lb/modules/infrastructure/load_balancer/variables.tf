# =============================================================================
# LOAD BALANCER MODULE VARIABLES
# =============================================================================

variable "load_balancer_type" {
  description = "Type of load balancer to deploy: nlb, haproxy, or nginx"
  type        = string
  
  validation {
    condition     = contains(["nlb", "haproxy", "nginx"], var.load_balancer_type)
    error_message = "Load balancer type must be 'nlb', 'haproxy', or 'nginx'."
  }
}

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

# =============================================================================
# NETWORK CONFIGURATION
# =============================================================================

variable "vpc_id" {
  description = "VPC ID where load balancer will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for load balancer deployment"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for internal communication"
  type        = list(string)
}

# =============================================================================
# REDIS ENTERPRISE CLUSTER INFORMATION
# =============================================================================

variable "instance_ids" {
  description = "List of Redis Enterprise instance IDs"
  type        = list(string)
}

variable "private_ips" {
  description = "List of Redis Enterprise instance private IPs"
  type        = list(string)
}

variable "public_ips" {
  description = "List of Redis Enterprise instance public IPs"
  type        = list(string)
}

# =============================================================================
# EC2-BASED LOAD BALANCER CONFIGURATION (HAPROXY & NGINX)
# =============================================================================

variable "key_name" {
  description = "EC2 key pair name for HAProxy/NGINX instances (required for haproxy and nginx types)"
  type        = string
  default     = ""
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for HAProxy/NGINX configuration (required for haproxy and nginx types)"
  type        = string
  default     = ""
}

variable "platform" {
  description = "Platform for HAProxy/NGINX instances (ubuntu or rhel)"
  type        = string
  default     = "ubuntu"
}

variable "haproxy_instance_type" {
  description = "EC2 instance type for HAProxy load balancers"
  type        = string
  default     = "t3.medium"
}

# =============================================================================
# NGINX SPECIFIC CONFIGURATION
# =============================================================================

variable "nginx_instance_type" {
  description = "EC2 instance type for NGINX load balancers"
  type        = string
  default     = "t3.medium"
}

variable "nginx_instance_count" {
  description = "Number of NGINX instances to deploy for high availability"
  type        = number
  default     = 2
}

# =============================================================================
# NGINX PORT CONFIGURATION
# =============================================================================

variable "frontend_database_port" {
  description = "Port on load balancer for Redis database connections (NGINX only)"
  type        = number
  default     = 6379
}

variable "backend_database_port" {
  description = "Port on Redis Enterprise nodes for database connections (NGINX only)"
  type        = number
  default     = 12000
}

variable "frontend_api_port" {
  description = "Port on load balancer for Redis Enterprise API (NGINX only)"
  type        = number
  default     = 9443
}

variable "backend_api_port" {
  description = "Port on Redis Enterprise nodes for API (NGINX only)"
  type        = number
  default     = 9443
}

variable "frontend_ui_port" {
  description = "Port on load balancer for Redis Enterprise UI (NGINX only)"
  type        = number
  default     = 443
}

variable "backend_ui_port" {
  description = "Port on Redis Enterprise nodes for UI (NGINX only)"
  type        = number
  default     = 8443
}

variable "additional_database_ports" {
  description = "Additional database ports to load balance (NGINX only)"
  type = list(object({
    name          = string
    frontend_port = number
    backend_port  = number
  }))
  default = null
}

variable "database_port_range_start" {
  description = "Start of database port range to open for Redis Enterprise databases (NGINX only)"
  type        = number
  default     = null
}

variable "database_port_range_end" {
  description = "End of database port range to open for Redis Enterprise databases (NGINX only)"
  type        = number
  default     = null
}

# =============================================================================
# NGINX LOAD BALANCING CONFIGURATION
# =============================================================================

variable "database_lb_method" {
  description = "Load balancing method for database connections (NGINX only)"
  type        = string
  default     = "least_conn"
}

variable "api_lb_method" {
  description = "Load balancing method for API connections (NGINX only)"
  type        = string
  default     = "round_robin"
}

variable "ui_lb_method" {
  description = "Load balancing method for UI connections (NGINX only)"
  type        = string
  default     = "ip_hash"
}

# =============================================================================
# NGINX HEALTH CHECK CONFIGURATION
# =============================================================================

variable "max_fails" {
  description = "Number of failed attempts before marking a server as unavailable (NGINX only)"
  type        = number
  default     = 3
}

variable "fail_timeout" {
  description = "Time in seconds a server is marked unavailable after max_fails (NGINX only)"
  type        = string
  default     = "30s"
}

variable "proxy_timeout" {
  description = "Timeout for establishing connection to backend (NGINX only)"
  type        = string
  default     = "1s"
}

# =============================================================================
# SECURITY AND ACCESS
# =============================================================================

variable "allow_access_from" {
  description = "List of CIDR blocks allowed to access the load balancer"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Tags to apply to load balancer resources"
  type        = map(string)
  default     = {}
}