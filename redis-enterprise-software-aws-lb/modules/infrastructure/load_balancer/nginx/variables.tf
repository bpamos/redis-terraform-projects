# =============================================================================
# NGINX LOAD BALANCER VARIABLES
# =============================================================================

# =============================================================================
# INFRASTRUCTURE CONFIGURATION
# =============================================================================

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where NGINX will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for NGINX deployment"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs (for reference)"
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
# EC2 INSTANCE CONFIGURATION
# =============================================================================

variable "key_name" {
  description = "EC2 key pair name for NGINX instances"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for NGINX configuration"
  type        = string
}

variable "platform" {
  description = "Platform for NGINX instances (ubuntu or rhel)"
  type        = string
  default     = "ubuntu"
  
  validation {
    condition     = contains(["ubuntu", "rhel"], var.platform)
    error_message = "Platform must be either 'ubuntu' or 'rhel'."
  }
}

variable "instance_type" {
  description = "EC2 instance type for NGINX load balancers"
  type        = string
  default     = "t3.medium"
}

variable "nginx_instance_count" {
  description = "Number of NGINX instances to deploy for high availability"
  type        = number
  default     = 2
  
  validation {
    condition     = var.nginx_instance_count >= 1 && var.nginx_instance_count <= 10
    error_message = "NGINX instance count must be between 1 and 10."
  }
}

# =============================================================================
# LOAD BALANCER PORT CONFIGURATION
# =============================================================================

variable "frontend_database_port" {
  description = "Port on load balancer for Redis database connections"
  type        = number
  default     = 6379
}

variable "backend_database_port" {
  description = "Port on Redis Enterprise nodes for database connections"
  type        = number
  default     = 12000
}

variable "frontend_api_port" {
  description = "Port on load balancer for Redis Enterprise API"
  type        = number
  default     = 9443
}

variable "backend_api_port" {
  description = "Port on Redis Enterprise nodes for API"
  type        = number
  default     = 9443
}

variable "frontend_ui_port" {
  description = "Port on load balancer for Redis Enterprise UI"
  type        = number
  default     = 443
}

variable "backend_ui_port" {
  description = "Port on Redis Enterprise nodes for UI"
  type        = number
  default     = 8443
}

variable "additional_database_ports" {
  description = "Additional database ports to load balance"
  type = list(object({
    name          = string
    frontend_port = number
    backend_port  = number
  }))
  default = null
}

variable "database_port_range_start" {
  description = "Start of database port range to open for Redis Enterprise databases (inclusive)"
  type        = number
  default     = null
}

variable "database_port_range_end" {
  description = "End of database port range to open for Redis Enterprise databases (inclusive)"
  type        = number
  default     = null
}

# =============================================================================
# NGINX CONFIGURATION OPTIONS
# =============================================================================

variable "worker_processes" {
  description = "Number of NGINX worker processes (auto or number)"
  type        = string
  default     = "auto"
}

variable "worker_connections" {
  description = "Maximum number of connections per worker process"
  type        = number
  default     = 4096
}

variable "worker_rlimit_nofile" {
  description = "Maximum number of open files per worker process"
  type        = number
  default     = 8192
}

# =============================================================================
# LOAD BALANCING CONFIGURATION
# =============================================================================

variable "database_lb_method" {
  description = "Load balancing method for database connections"
  type        = string
  default     = "least_conn"
  
  validation {
    condition     = contains(["least_conn", "round_robin", "ip_hash", "hash"], var.database_lb_method)
    error_message = "Database LB method must be one of: least_conn, round_robin, ip_hash, hash."
  }
}

variable "api_lb_method" {
  description = "Load balancing method for API connections"
  type        = string
  default     = "round_robin"
  
  validation {
    condition     = contains(["least_conn", "round_robin", "ip_hash", "hash"], var.api_lb_method)
    error_message = "API LB method must be one of: least_conn, round_robin, ip_hash, hash."
  }
}

variable "ui_lb_method" {
  description = "Load balancing method for UI connections"
  type        = string
  default     = "ip_hash"
  
  validation {
    condition     = contains(["least_conn", "round_robin", "ip_hash", "hash"], var.ui_lb_method)
    error_message = "UI LB method must be one of: least_conn, round_robin, ip_hash, hash."
  }
}

# =============================================================================
# HEALTH CHECK CONFIGURATION
# =============================================================================

variable "max_fails" {
  description = "Number of failed attempts before marking a server as unavailable"
  type        = number
  default     = 3
}

variable "fail_timeout" {
  description = "Time in seconds a server is marked unavailable after max_fails"
  type        = string
  default     = "30s"
}

variable "health_check_interval" {
  description = "Interval for active health checks (NGINX Plus feature)"
  type        = string
  default     = "10s"
}

# =============================================================================
# TIMEOUT CONFIGURATION
# =============================================================================

variable "proxy_timeout" {
  description = "Timeout for establishing connection to backend"
  type        = string
  default     = "1s"
}

variable "proxy_connect_timeout" {
  description = "Timeout for connecting to backend server"
  type        = string
  default     = "1s"
}

variable "proxy_read_timeout" {
  description = "Timeout for reading data from backend"
  type        = string
  default     = "30s"
}

variable "proxy_send_timeout" {
  description = "Timeout for sending data to backend"
  type        = string
  default     = "30s"
}

# =============================================================================
# SECURITY AND ACCESS CONTROL
# =============================================================================

variable "allow_access_from" {
  description = "List of CIDR blocks allowed to access the load balancer"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_ssl_passthrough" {
  description = "Enable SSL passthrough for Redis Enterprise UI"
  type        = bool
  default     = true
}

# =============================================================================
# LOGGING AND MONITORING
# =============================================================================

variable "enable_access_log" {
  description = "Enable NGINX access logging"
  type        = bool
  default     = true
}

variable "enable_stream_log" {
  description = "Enable NGINX stream module logging"
  type        = bool
  default     = true
}

variable "log_level" {
  description = "NGINX error log level (debug, info, notice, warn, error, crit)"
  type        = string
  default     = "warn"
  
  validation {
    condition     = contains(["debug", "info", "notice", "warn", "error", "crit"], var.log_level)
    error_message = "Log level must be one of: debug, info, notice, warn, error, crit."
  }
}

# =============================================================================
# RESOURCE TAGGING
# =============================================================================

variable "tags" {
  description = "Tags to apply to NGINX resources"
  type        = map(string)
  default     = {}
}