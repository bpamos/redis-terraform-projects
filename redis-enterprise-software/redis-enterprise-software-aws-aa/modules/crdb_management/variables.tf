# =============================================================================
# CRDB MANAGEMENT MODULE VARIABLES
# =============================================================================

variable "create_crdb" {
  description = "Whether to create the Active-Active CRDB database"
  type        = bool
  default     = true
}

variable "verify_crdb" {
  description = "Whether to verify CRDB creation on all clusters"
  type        = bool
  default     = true
}

variable "crdb_name" {
  description = "Name for the Active-Active CRDB database (max 63 chars, alphanumeric + hyphens)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{1,63}$", var.crdb_name))
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
    condition     = var.crdb_memory_size >= 104857600 # 100MB minimum
    error_message = "CRDB memory size must be at least 100MB (104857600 bytes)."
  }
}

variable "enable_replication" {
  description = "Enable replication for CRDB high availability (recommended)"
  type        = bool
  default     = true
}

variable "enable_sharding" {
  description = "Enable sharding for CRDB (cannot be changed after creation)"
  type        = bool
  default     = false
}

variable "shards_count" {
  description = "Number of shards for CRDB (if sharding is enabled)"
  type        = number
  default     = 1

  validation {
    condition     = var.shards_count >= 1 && var.shards_count <= 512
    error_message = "Shards count must be between 1 and 512."
  }
}

variable "enable_causal_consistency" {
  description = "Enable causal consistency for CRDB"
  type        = bool
  default     = true
}

variable "aof_policy" {
  description = "AOF persistence policy (Active-Active only supports AOF)"
  type        = string
  default     = "appendfsync-every-sec"

  validation {
    condition     = contains(["appendfsync-every-sec", "appendfsync-always"], var.aof_policy)
    error_message = "AOF policy must be 'appendfsync-every-sec' or 'appendfsync-always'."
  }
}

variable "participating_clusters" {
  description = "Map of participating cluster configurations"
  type = map(object({
    cluster_fqdn    = string
    primary_node_ip = string  # Public IP of primary node for API access
  }))

  validation {
    condition     = length(var.participating_clusters) >= 2
    error_message = "At least 2 participating clusters are required for Active-Active."
  }
}

variable "cluster_username" {
  description = "Username for Redis Enterprise cluster administration"
  type        = string

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.cluster_username))
    error_message = "Cluster username must be a valid email address."
  }
}

variable "cluster_password" {
  description = "Password for Redis Enterprise cluster administration"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.cluster_password) >= 4
    error_message = "Cluster password must be at least 4 characters long."
  }
}
