# =============================================================================
# PROJECT CONFIGURATION
# =============================================================================

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "redis-enterprise"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.name_prefix)) && length(var.name_prefix) <= 20
    error_message = "Name prefix must start with a letter, contain only lowercase letters, numbers, and hyphens, and be 20 characters or less."
  }
}

variable "owner" {
  description = "Owner of the infrastructure"
  type        = string

  validation {
    condition     = length(var.owner) > 0 && length(var.owner) <= 50
    error_message = "Owner must be a non-empty string with 50 characters or less."
  }
}

variable "project" {
  description = "Project or environment name"
  type        = string
  default     = "redis-enterprise-software-aws"

  validation {
    condition     = length(var.project) > 0 && length(var.project) <= 50
    error_message = "Project must be a non-empty string with 50 characters or less."
  }
}

# =============================================================================
# AWS INFRASTRUCTURE
# =============================================================================

variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-west-2"
  
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be in the format like us-west-2, us-east-1, etc."
  }
}

# =============================================================================
# LOAD BALANCER CONFIGURATION
# =============================================================================

variable "load_balancer_type" {
  description = "Load balancer type: 'nlb' (AWS Network Load Balancer - managed), 'haproxy' (HAProxy on EC2 - self-managed), or 'nginx' (NGINX on EC2 - self-managed with stream module)"
  type        = string
  default     = "nlb"

  validation {
    condition     = contains(["nlb", "haproxy", "nginx"], var.load_balancer_type)
    error_message = "Load balancer type must be 'nlb', 'haproxy', or 'nginx'."
  }
}

# =============================================================================
# NGINX LOAD BALANCER CONFIGURATION
# =============================================================================

variable "nginx_instance_type" {
  description = "EC2 instance type for NGINX load balancers (only used when load_balancer_type = 'nginx')"
  type        = string
  default     = "t3.medium"
}

variable "nginx_instance_count" {
  description = "Number of NGINX instances to deploy for high availability (only used when load_balancer_type = 'nginx')"
  type        = number
  default     = 2
  
  validation {
    condition     = var.nginx_instance_count >= 1 && var.nginx_instance_count <= 10
    error_message = "NGINX instance count must be between 1 and 10."
  }
}

variable "frontend_database_port" {
  description = "Port on load balancer for Redis database connections (only used when load_balancer_type = 'nginx')"
  type        = number
  default     = 6379
}

variable "backend_database_port" {
  description = "Port on Redis Enterprise nodes for database connections (only used when load_balancer_type = 'nginx')"
  type        = number
  default     = 12000
}

variable "frontend_api_port" {
  description = "Port on load balancer for Redis Enterprise API (only used when load_balancer_type = 'nginx')"
  type        = number
  default     = 9443
}

variable "backend_api_port" {
  description = "Port on Redis Enterprise nodes for API (only used when load_balancer_type = 'nginx')"
  type        = number
  default     = 9443
}

variable "frontend_ui_port" {
  description = "Port on load balancer for Redis Enterprise UI (only used when load_balancer_type = 'nginx')"
  type        = number
  default     = 443
}

variable "backend_ui_port" {
  description = "Port on Redis Enterprise nodes for UI (only used when load_balancer_type = 'nginx')"
  type        = number
  default     = 8443
}

variable "additional_database_ports" {
  description = "Additional database ports to load balance (only used when load_balancer_type = 'nginx')"
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
  
  validation {
    condition = var.database_port_range_start == null || (var.database_port_range_start >= 10000 && var.database_port_range_start <= 19999)
    error_message = "Database port range start must be between 10000-19999 (Redis Enterprise database port range)."
  }
}

variable "database_port_range_end" {
  description = "End of database port range to open for Redis Enterprise databases (inclusive)"
  type        = number
  default     = null
  
  validation {
    condition = var.database_port_range_end == null || (var.database_port_range_end >= 10000 && var.database_port_range_end <= 19999)
    error_message = "Database port range end must be between 10000-19999 (Redis Enterprise database port range)."
  }
}

variable "database_lb_method" {
  description = "Load balancing method for database connections: least_conn, round_robin, ip_hash, hash (only used when load_balancer_type = 'nginx')"
  type        = string
  default     = "least_conn"
  
  validation {
    condition     = contains(["least_conn", "round_robin", "ip_hash", "hash"], var.database_lb_method)
    error_message = "Database LB method must be one of: least_conn, round_robin, ip_hash, hash."
  }
}

variable "api_lb_method" {
  description = "Load balancing method for API connections: least_conn, round_robin, ip_hash, hash (only used when load_balancer_type = 'nginx')"
  type        = string
  default     = "round_robin"
  
  validation {
    condition     = contains(["least_conn", "round_robin", "ip_hash", "hash"], var.api_lb_method)
    error_message = "API LB method must be one of: least_conn, round_robin, ip_hash, hash."
  }
}

variable "ui_lb_method" {
  description = "Load balancing method for UI connections: least_conn, round_robin, ip_hash, hash (only used when load_balancer_type = 'nginx')"
  type        = string
  default     = "ip_hash"
  
  validation {
    condition     = contains(["least_conn", "round_robin", "ip_hash", "hash"], var.ui_lb_method)
    error_message = "UI LB method must be one of: least_conn, round_robin, ip_hash, hash."
  }
}

variable "max_fails" {
  description = "Number of failed attempts before marking a server as unavailable (only used when load_balancer_type = 'nginx')"
  type        = number
  default     = 3
}

variable "fail_timeout" {
  description = "Time in seconds a server is marked unavailable after max_fails (only used when load_balancer_type = 'nginx')"
  type        = string
  default     = "30s"
}

variable "proxy_timeout" {
  description = "Timeout for establishing connection to backend (only used when load_balancer_type = 'nginx')"
  type        = string
  default     = "1s"
}

# =============================================================================
# VPC NETWORKING
# =============================================================================

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  
  validation {
    condition     = length(var.public_subnet_cidrs) >= 3
    error_message = "At least 3 public subnets are required for Redis Enterprise cluster."
  }
}

variable "private_subnet_cidrs" {
  description = "List of CIDRs for private subnets"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  
  validation {
    condition     = length(var.private_subnet_cidrs) >= 3
    error_message = "At least 3 private subnets are required for Redis Enterprise cluster."
  }
}

# =============================================================================
# SECURITY CONFIGURATION
# =============================================================================

variable "allow_ssh_from" {
  description = "List of CIDRs allowed to SSH into EC2 instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for cidr in var.allow_ssh_from : can(cidrhost(cidr, 0))
    ])
    error_message = "All SSH CIDR blocks must be valid IPv4 CIDR blocks."
  }
}


# =============================================================================
# EC2 CONFIGURATION
# =============================================================================

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
  
  validation {
    condition     = length(var.key_name) > 0
    error_message = "EC2 key pair name cannot be empty."
  }
}

variable "ssh_private_key_path" {
  description = "Path to the private key file for SSH access"
  type        = string
  
  validation {
    condition     = length(var.ssh_private_key_path) > 0 && can(regex("\\.(pem|key)$", var.ssh_private_key_path))
    error_message = "SSH private key path must be provided and end with .pem or .key."
  }
}

# =============================================================================
# REDIS ENTERPRISE CLUSTER CONFIGURATION
# =============================================================================

variable "platform" {
  description = "Operating system platform for Redis Enterprise nodes. Choose 'ubuntu' for Ubuntu 22.04 LTS or 'rhel' for Red Hat Enterprise Linux 9. Each platform uses appropriate AMI, SSH user, installation scripts, and system configurations."
  type        = string
  default     = "ubuntu"

  validation {
    condition     = contains(["ubuntu", "rhel"], var.platform)
    error_message = "Platform must be either 'ubuntu' or 'rhel'."
  }
}

variable "node_count" {
  description = "Number of Redis Enterprise nodes in the cluster"
  type        = number
  default     = 3

  validation {
    condition     = var.node_count >= 3
    error_message = "Node count must be at least 3 for Redis Enterprise cluster."
  }
}

variable "instance_type" {
  description = "EC2 instance type for Redis Enterprise nodes"
  type        = string
  default     = "t3.xlarge"
}

variable "node_root_size" {
  description = "Root EBS volume size in GB for Redis Enterprise nodes"
  type        = number
  default     = 50
}

variable "data_volume_size" {
  description = "Size of data EBS volume in GB (should be RAM x 4 for testing)"
  type        = number
  default     = 64
}

variable "data_volume_type" {
  description = "EBS volume type for data storage"
  type        = string
  default     = "gp3"
}

variable "persistent_volume_size" {
  description = "Size of persistent EBS volume in GB (should be RAM x 4 for testing)"
  type        = number
  default     = 64
}

variable "persistent_volume_type" {
  description = "EBS volume type for persistent storage"
  type        = string
  default     = "gp3"
}

variable "ebs_encryption_enabled" {
  description = "Enable EBS volume encryption"
  type        = bool
  default     = true
}

variable "re_download_url" {
  description = "Redis Enterprise download URL - must be provided by user for their desired version"
  type        = string

  validation {
    condition     = length(var.re_download_url) > 0 && can(regex("^https://", var.re_download_url))
    error_message = "Redis Enterprise download URL must be specified and be a valid HTTPS URL. Please provide the download URL for your desired version in terraform.tfvars."
  }
}

variable "cluster_username" {
  description = "Username for Redis Enterprise cluster administration"
  type        = string
  default     = "admin@redis.com"

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.cluster_username))
    error_message = "Cluster username must be a valid email address."
  }
}

variable "cluster_password" {
  description = "Password for Redis Enterprise cluster administration"
  type        = string
  default     = "RedisEnterprise123!"

  validation {
    condition     = length(var.cluster_password) >= 4
    error_message = "Cluster password must be at least 4 characters long."
  }
}

variable "flash_enabled" {
  description = "Enable Redis on Flash (RoF) capability"
  type        = bool
  default     = false
}

variable "rack_awareness" {
  description = "Enable rack/zone awareness for high availability"
  type        = bool
  default     = true
}

# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================

variable "create_sample_database" {
  description = "Create a sample Redis database automatically after cluster setup"
  type        = bool
  default     = true
}

variable "sample_db_name" {
  description = "Name for the sample Redis database"
  type        = string
  default     = "demo"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.sample_db_name)) && length(var.sample_db_name) <= 20
    error_message = "Database name must start with a letter, contain only lowercase letters, numbers, and hyphens, and be 20 characters or less."
  }
}

variable "sample_db_port" {
  description = "Port for the sample Redis database"
  type        = number
  default     = 12000

  validation {
    condition     = var.sample_db_port >= 10000 && var.sample_db_port <= 19999
    error_message = "Database port must be between 10000 and 19999."
  }
}

variable "sample_db_memory" {
  description = "Memory size in MB for the sample Redis database"
  type        = number
  default     = 100

  validation {
    condition     = var.sample_db_memory >= 50 && var.sample_db_memory <= 10000
    error_message = "Database memory must be between 50 and 10000 MB."
  }
}

# =============================================================================
# RESOURCE TAGGING
# =============================================================================

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}