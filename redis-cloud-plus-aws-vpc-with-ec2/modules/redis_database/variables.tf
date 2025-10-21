# =============================================================================
# REDIS DATABASE VARIABLES
# =============================================================================

variable "subscription_id" {
  description = "Redis Cloud subscription ID"
  type        = string
}

variable "database_name" {
  description = "Name of the Redis database"
  type        = string
  default     = "redis-db"
}

variable "dataset_size_in_gb" {
  description = "Expected dataset size in GB for the Redis database"
  type        = number
  default     = 1

  validation {
    condition     = var.dataset_size_in_gb > 0
    error_message = "Dataset size must be greater than 0 GB."
  }
}

variable "data_persistence" {
  description = "Persistence mode for Redis database"
  type        = string
  default     = "aof-every-1-second"

  validation {
    condition = contains([
      "none",
      "aof-every-1-second",
      "aof-every-write",
      "snapshot-every-1-hour",
      "snapshot-every-6-hours",
      "snapshot-every-12-hours"
    ], var.data_persistence)
    error_message = "Data persistence must be a valid Redis persistence mode."
  }
}

variable "throughput_by" {
  description = "Method for measuring database throughput"
  type        = string
  default     = "operations-per-second"

  validation {
    condition     = contains(["operations-per-second", "number-of-shards"], var.throughput_by)
    error_message = "Throughput measurement must be 'operations-per-second' or 'number-of-shards'."
  }
}

variable "throughput_value" {
  description = "Expected throughput value for the selected measurement method"
  type        = number
  default     = 1000

  validation {
    condition     = var.throughput_value > 0
    error_message = "Throughput value must be greater than 0."
  }
}

variable "replication" {
  description = "Whether to enable replication"
  type        = bool
  default     = true
}

variable "redis_version" {
  description = "Redis version for the database. If omitted, uses Redis Cloud default"
  type        = string
  default     = null

  validation {
    condition = var.redis_version == null || contains([
      "6.0", "6.2", "7.0", "7.2", "7.4"
    ], var.redis_version)
    error_message = "Redis version must be a valid supported version or null for default."
  }
}

variable "enable_tls" {
  description = "Enable TLS encryption for client connections"
  type        = bool
  default     = false
}

variable "modules" {
  description = "List of Redis modules to enable (e.g., RedisJSON, RedisTimeSeries, RediSearch)"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for module in var.modules : contains([
        "RedisJSON", "RedisTimeSeries", "RediSearch", "RedisBloom"
      ], module)
    ])
    error_message = "All modules must be valid Redis Enterprise modules."
  }
}

# =============================================================================
# ALERT CONFIGURATION
# =============================================================================

variable "enable_alerts" {
  description = "Enable database monitoring alerts"
  type        = bool
  default     = false
}

variable "dataset_size_alert_threshold" {
  description = "Dataset size alert threshold percentage (0-100)"
  type        = number
  default     = 95

  validation {
    condition     = var.dataset_size_alert_threshold >= 0 && var.dataset_size_alert_threshold <= 100
    error_message = "Dataset size alert threshold must be between 0 and 100."
  }
}


variable "tags" {
  description = "Key-value tags to associate with resources"
  type        = map(string)
  default     = {}
}

# =============================================================================
# ADVANCED DATABASE CONFIGURATION
# =============================================================================

variable "protocol" {
  description = "The protocol that will be used to access the database (either 'redis' or 'memcached')"
  type        = string
  default     = null

  validation {
    condition     = var.protocol == null ? true : contains(["redis", "memcached"], var.protocol)
    error_message = "Protocol must be either 'redis' or 'memcached'."
  }
}

variable "support_oss_cluster_api" {
  description = "Support Redis open-source (OSS) Cluster API"
  type        = bool
  default     = null
}

variable "resp_version" {
  description = "Database's RESP version (either 'resp2' or 'resp3'). Must be compatible with the Redis version"
  type        = string
  default     = null

  validation {
    condition     = var.resp_version == null ? true : contains(["resp2", "resp3"], var.resp_version)
    error_message = "RESP version must be either 'resp2' or 'resp3'."
  }
}

variable "external_endpoint_for_oss_cluster_api" {
  description = "Should use the external endpoint for open-source (OSS) Cluster API. Can only be enabled if OSS Cluster API support is enabled"
  type        = bool
  default     = null
}

variable "client_ssl_certificate" {
  description = "SSL certificate to authenticate user connections"
  type        = string
  default     = null
}

variable "client_tls_certificates" {
  description = "A list of TLS certificates to authenticate user connections"
  type        = list(string)
  default     = null
}

variable "replica_of" {
  description = "Set of Redis database URIs (format: redis://user:password@host:port) that this database will be a replica of. Cannot be enabled when support_oss_cluster_api is enabled"
  type        = list(string)
  default     = null
}

variable "data_eviction" {
  description = "The data items eviction policy (allkeys-lru, allkeys-lfu, allkeys-random, volatile-lru, volatile-lfu, volatile-random, volatile-ttl, noeviction)"
  type        = string
  default     = null

  validation {
    condition = var.data_eviction == null ? true : contains([
      "allkeys-lru", "allkeys-lfu", "allkeys-random",
      "volatile-lru", "volatile-lfu", "volatile-random",
      "volatile-ttl", "noeviction"
    ], var.data_eviction)
    error_message = "Data eviction must be a valid Redis eviction policy."
  }
}

variable "password" {
  description = "Password to access the database. If omitted, a random 32 character long alphanumeric password will be automatically generated"
  type        = string
  default     = null
  sensitive   = true
}

variable "average_item_size_in_bytes" {
  description = "Relevant only to ram-and-flash clusters. Estimated average size (measured in bytes) of the items stored in the database"
  type        = number
  default     = null

  validation {
    condition     = var.average_item_size_in_bytes == null ? true : var.average_item_size_in_bytes > 0
    error_message = "Average item size must be greater than 0 bytes."
  }
}

variable "source_ips" {
  description = "List of source IP addresses or subnet masks allowed to connect to the database (e.g., ['192.168.10.0/32', '192.168.12.0/24'])"
  type        = list(string)
  default     = null
}

variable "hashing_policy" {
  description = "List of regular expression rules to shard the database by. Cannot be set when support_oss_cluster_api is true"
  type        = list(string)
  default     = null
}

variable "port" {
  description = "TCP port on which the database is available - must be between 10000 and 19999"
  type        = number
  default     = null

  validation {
    condition     = var.port == null ? true : (var.port >= 10000 && var.port <= 19999)
    error_message = "Port must be between 10000 and 19999."
  }
}

variable "enable_default_user" {
  description = "When true enables connecting to the database with the default user"
  type        = bool
  default     = null
}

# =============================================================================
# REMOTE BACKUP CONFIGURATION
# =============================================================================

variable "remote_backup_interval" {
  description = "Interval between backups (format: 'every-x-hours' where x is 1,2,4,6,12,24)"
  type        = string
  default     = null

  validation {
    condition = var.remote_backup_interval == null ? true : contains([
      "every-1-hours", "every-2-hours", "every-4-hours",
      "every-6-hours", "every-12-hours", "every-24-hours"
    ], var.remote_backup_interval)
    error_message = "Backup interval must be in format 'every-x-hours' where x is 1,2,4,6,12, or 24."
  }
}

variable "remote_backup_time_utc" {
  description = "Hour automatic backups are made (format: 'HH:00'). Only applicable when interval is every-12-hours or every-24-hours"
  type        = string
  default     = null

  validation {
    condition     = var.remote_backup_time_utc == null ? true : can(regex("^([0-1]?[0-9]|2[0-3]):00$", var.remote_backup_time_utc))
    error_message = "Backup time must be in format 'HH:00' (e.g., '14:00')."
  }
}

variable "remote_backup_storage_type" {
  description = "Provider of the storage location for backups (e.g., 'aws-s3', 'gcp-storage', 'azure-blob-storage')"
  type        = string
  default     = null
}

variable "remote_backup_storage_path" {
  description = "URI representing the backup storage location"
  type        = string
  default     = null
}