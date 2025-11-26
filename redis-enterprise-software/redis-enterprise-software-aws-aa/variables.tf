# =============================================================================
# REDIS ENTERPRISE ACTIVE-ACTIVE MULTI-REGION DEPLOYMENT VARIABLES
# =============================================================================

# =============================================================================
# PROJECT CONFIGURATION
# =============================================================================

variable "user_prefix" {
  description = "Your unique identifier (e.g., your name or team)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.user_prefix)) && length(var.user_prefix) <= 10
    error_message = "User prefix must start with a letter, contain only lowercase letters, numbers, and hyphens, and be 10 characters or less."
  }
}

variable "cluster_name" {
  description = "Redis Enterprise cluster name suffix"
  type        = string
  default     = "redis-aa"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.cluster_name)) && length(var.cluster_name) <= 15
    error_message = "Cluster name must start with a letter, contain only lowercase letters, numbers, and hyphens, and be 15 characters or less."
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
  default     = "redis-enterprise-active-active"

  validation {
    condition     = length(var.project) > 0 && length(var.project) <= 50
    error_message = "Project must be a non-empty string with 50 characters or less."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# =============================================================================
# MULTI-REGION CONFIGURATION
# =============================================================================

variable "regions" {
  description = "Map of AWS regions and their configurations for Active-Active deployment"
  type = map(object({
    vpc_cidr             = string
    key_name             = string
    ssh_key_path         = string
    availability_zones   = optional(list(string), [])
    public_subnet_cidrs  = optional(list(string), ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"])
    private_subnet_cidrs = optional(list(string), ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"])
  }))

  validation {
    condition     = length(var.regions) >= 2
    error_message = "At least 2 regions are required for Active-Active deployment."
  }

  validation {
    condition = alltrue([
      for region, config in var.regions : can(cidrhost(config.vpc_cidr, 0))
    ])
    error_message = "All VPC CIDRs must be valid IPv4 CIDR blocks."
  }

  validation {
    condition = alltrue([
      for region, config in var.regions : length(config.key_name) > 0
    ])
    error_message = "All regions must have a key_name specified."
  }

  validation {
    condition = alltrue([
      for region, config in var.regions : length(config.ssh_key_path) > 0
    ])
    error_message = "All regions must have an ssh_key_path specified."
  }
}

variable "allow_ssh_from" {
  description = "List of CIDRs allowed to SSH into EC2 instances (applies to all regions)"
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
# DNS CONFIGURATION
# =============================================================================

variable "dns_hosted_zone_id" {
  description = "Route53 hosted zone ID for DNS records"
  type        = string

  validation {
    condition     = length(var.dns_hosted_zone_id) > 0
    error_message = "DNS hosted zone ID cannot be empty."
  }
}

variable "create_dns_records" {
  description = "Create DNS A records for Redis Enterprise nodes"
  type        = bool
  default     = true
}

# =============================================================================
# REDIS ENTERPRISE CLUSTER CONFIGURATION
# =============================================================================

variable "platform" {
  description = "Operating system platform for Redis Enterprise nodes (ubuntu or rhel)"
  type        = string
  default     = "ubuntu"

  validation {
    condition     = contains(["ubuntu", "rhel"], var.platform)
    error_message = "Platform must be either 'ubuntu' or 'rhel'."
  }
}

variable "node_count_per_region" {
  description = "Number of Redis Enterprise nodes per region"
  type        = number
  default     = 3

  validation {
    condition     = var.node_count_per_region >= 3
    error_message = "Node count must be at least 3 for Redis Enterprise cluster."
  }
}

variable "instance_type" {
  description = "EC2 instance type for Redis Enterprise nodes"
  type        = string
  default     = "t3.xlarge"
}

variable "associate_public_ip_address" {
  description = "Associate public IP addresses with Redis Enterprise instances (true = public IPs, false = private IPs only)"
  type        = bool
  default     = true
}

variable "use_elastic_ips" {
  description = "Use Elastic IPs for Redis Enterprise instances (provides static IPs for Active-Active deployments)"
  type        = bool
  default     = true
}

variable "node_root_size" {
  description = "Root EBS volume size in GB for Redis Enterprise nodes"
  type        = number
  default     = 50
}

variable "data_volume_size" {
  description = "Size of data EBS volume in GB"
  type        = number
  default     = 64
}

variable "data_volume_type" {
  description = "EBS volume type for data storage"
  type        = string
  default     = "gp3"
}

variable "persistent_volume_size" {
  description = "Size of persistent EBS volume in GB"
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
  description = "Redis Enterprise download URL (must be same version across all regions)"
  type        = string

  validation {
    condition     = length(var.re_download_url) > 0 && can(regex("^https://", var.re_download_url))
    error_message = "Redis Enterprise download URL must be specified and be a valid HTTPS URL."
  }
}

variable "cluster_username" {
  description = "Username for Redis Enterprise cluster administration (same for all regions)"
  type        = string
  default     = "admin@admin.com"

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.cluster_username))
    error_message = "Cluster username must be a valid email address."
  }
}

variable "cluster_password" {
  description = "Password for Redis Enterprise cluster administration (same for all regions)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.cluster_password) >= 4
    error_message = "Cluster password must be at least 4 characters long."
  }

  validation {
    condition     = can(regex("^[A-Za-z0-9]+$", var.cluster_password))
    error_message = "Cluster password must contain only alphanumeric characters (no special characters)."
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
# SAMPLE DATABASE CONFIGURATION (PER REGION)
# =============================================================================

variable "create_sample_database" {
  description = "Create a sample Redis database automatically after cluster setup"
  type        = bool
  default     = false # Default to false for Active-Active (use CRDB instead)
}

variable "sample_db_name" {
  description = "Name for the sample Redis database (per region)"
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
  default     = 11000

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
# ACTIVE-ACTIVE (CRDB) DATABASE CONFIGURATION
# =============================================================================

variable "create_crdb_database" {
  description = "Automatically create Active-Active CRDB database after cluster deployment"
  type        = bool
  default     = true
}

variable "verify_crdb_creation" {
  description = "Verify CRDB creation on all participating clusters"
  type        = bool
  default     = true
}

variable "crdb_database_name" {
  description = "Name for the Active-Active CRDB database"
  type        = string
  default     = "active-active-db"

  validation {
    condition     = can(regex("^[a-z0-9-]{1,63}$", var.crdb_database_name))
    error_message = "CRDB name must be 1-63 characters, lowercase alphanumeric and hyphens only."
  }
}

variable "crdb_port" {
  description = "Port for CRDB database (cannot be changed after creation)"
  type        = number
  default     = 12000

  validation {
    condition     = var.crdb_port >= 10000 && var.crdb_port <= 19999
    error_message = "CRDB port must be between 10000-19999."
  }
}

variable "crdb_memory_size" {
  description = "Memory size in bytes for CRDB (applies across all instances)"
  type        = number
  default     = 1073741824 # 1GB

  validation {
    condition     = var.crdb_memory_size >= 104857600
    error_message = "CRDB memory size must be at least 100MB (104857600 bytes)."
  }
}

variable "crdb_enable_replication" {
  description = "Enable replication for CRDB high availability (recommended)"
  type        = bool
  default     = true
}

variable "crdb_enable_sharding" {
  description = "Enable sharding for CRDB (cannot be changed after creation)"
  type        = bool
  default     = false
}

variable "crdb_shards_count" {
  description = "Number of shards for CRDB (if sharding is enabled)"
  type        = number
  default     = 1

  validation {
    condition     = var.crdb_shards_count >= 1 && var.crdb_shards_count <= 512
    error_message = "Shards count must be between 1 and 512."
  }
}

variable "crdb_enable_causal_consistency" {
  description = "Enable causal consistency for CRDB"
  type        = bool
  default     = true
}

variable "crdb_aof_policy" {
  description = "AOF persistence policy for CRDB (Active-Active only supports AOF)"
  type        = string
  default     = "appendfsync-every-sec"

  validation {
    condition     = contains(["appendfsync-every-sec", "appendfsync-always"], var.crdb_aof_policy)
    error_message = "AOF policy must be 'appendfsync-every-sec' or 'appendfsync-always'."
  }
}

# =============================================================================
# TEST NODE CONFIGURATION
# =============================================================================

variable "enable_test_nodes" {
  description = "Create test nodes in each region for Redis testing"
  type        = bool
  default     = true
}

variable "test_node_instance_type" {
  description = "Instance type for test nodes in all regions"
  type        = string
  default     = "t3.small"
}
