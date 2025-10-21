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

variable "modules" {
  description = "List of Redis modules to enable (e.g., RedisJSON, RedisTimeSeries, RediSearch)"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for module in var.modules : contains([
        "RedisJSON", "RedisTimeSeries", "RediSearch", "RedisGraph",
        "RedisBloom", "RedisML", "RedisGears"
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