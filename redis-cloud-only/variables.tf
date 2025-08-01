# =============================================================================
# PROJECT CONFIGURATION
# =============================================================================

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
  default     = "redis-cloud-only-demo"

  validation {
    condition     = length(var.project) > 0 && length(var.project) <= 50
    error_message = "Project must be a non-empty string with 50 characters or less."
  }
}

# =============================================================================
# REDIS CLOUD CONFIGURATION
# =============================================================================

variable "rediscloud_api_key" {
  description = "Redis Cloud API key"
  type        = string
  sensitive   = true
}

variable "rediscloud_secret_key" {
  description = "Redis Cloud API secret key"
  type        = string
  sensitive   = true
}

variable "credit_card_type" {
  description = "Credit card type for Redis Cloud payment"
  type        = string
  default     = "Visa"

  validation {
    condition     = contains(["Visa", "Mastercard", "American Express", "Discover"], var.credit_card_type)
    error_message = "Credit card type must be Visa, Mastercard, American Express, or Discover."
  }
}

variable "credit_card_last_four" {
  description = "Last four digits of the credit card for Redis Cloud subscription"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{4}$", var.credit_card_last_four))
    error_message = "Credit card last four must be exactly 4 digits."
  }
}

variable "subscription_name" {
  description = "Name for the Redis Cloud subscription"
  type        = string
  default     = "redis-cloud-only-subscription"
}

variable "rediscloud_region" {
  description = "Redis Cloud deployment region"
  type        = string
  default     = "us-west-2"
}

variable "networking_deployment_cidr" {
  description = "CIDR block for Redis Cloud networking deployment"
  type        = string
  default     = "10.42.0.0/24"

  validation {
    condition     = can(cidrhost(var.networking_deployment_cidr, 0))
    error_message = "Networking deployment CIDR must be a valid IPv4 CIDR block."
  }
}

variable "preferred_azs" {
  description = "Preferred availability zones for Redis Cloud deployment. Leave empty to let Redis Cloud auto-select optimal zones."
  type        = list(string) 
  default     = []
}

# =============================================================================
# REDIS DATABASE CONFIGURATION
# =============================================================================

variable "memory_storage" {
  description = "Memory storage option (ram or ram-and-flash)"
  type        = string
  default     = "ram"

  validation {
    condition     = contains(["ram", "ram-and-flash"], var.memory_storage)
    error_message = "Memory storage must be either 'ram' or 'ram-and-flash'."
  }
}

variable "redis_version" {
  description = "Redis version to deploy"
  type        = string
  default     = "7.2"
}

variable "cloud_provider" {
  description = "Cloud provider for Redis Cloud (AWS only)"
  type        = string
  default     = "AWS"

  validation {
    condition     = var.cloud_provider == "AWS"
    error_message = "Only AWS cloud provider is supported."
  }
}

variable "cloud_account_id" {
  description = "Cloud account identifier for Redis Cloud subscription. Default: Redis Labs internal cloud account (ID=1). Note: GCP subscriptions can only use Redis Labs internal cloud account."
  type        = number
  default     = 1
  
  validation {
    condition     = var.cloud_account_id >= 1
    error_message = "Cloud account ID must be 1 or greater. Use 1 for Redis Labs internal cloud account."
  }
}

variable "multi_az" {
  description = "Deploy Redis across multiple availability zones"
  type        = bool
  default     = true
}

variable "dataset_size_in_gb" {
  description = "Expected dataset size in GB"
  type        = number
  default     = 1

  validation {
    condition     = var.dataset_size_in_gb > 0 && var.dataset_size_in_gb <= 1000
    error_message = "Dataset size must be between 1 and 1000 GB."
  }
}

variable "database_quantity" {
  description = "Number of databases to create"
  type        = number
  default     = 1

  validation {
    condition     = var.database_quantity >= 1 && var.database_quantity <= 10
    error_message = "Database quantity must be between 1 and 10."
  }
}

variable "replication" {
  description = "Enable Redis replication"
  type        = bool
  default     = true
}

variable "throughput_by" {
  description = "Throughput measurement method"
  type        = string
  default     = "operations-per-second"

  validation {
    condition     = contains(["operations-per-second", "number-of-shards"], var.throughput_by)
    error_message = "Throughput measurement must be 'operations-per-second' or 'number-of-shards'."
  }
}

variable "throughput_value" {
  description = "Expected throughput value"
  type        = number
  default     = 1000

  validation {
    condition     = var.throughput_value > 0
    error_message = "Throughput value must be greater than 0."
  }
}

variable "modules_enabled" {
  description = "List of Redis modules to enable"
  type        = list(string)
  default     = ["RedisJSON"]

  validation {
    condition = alltrue([
      for module in var.modules_enabled : contains(["RedisJSON", "RedisTimeSeries", "RediSearch", "RedisGraph", "RedisBloom", "RedisML", "RedisGears"], module)
    ])
    error_message = "All modules must be valid Redis Enterprise modules."
  }
}

variable "database_name" {
  description = "Name of the Redis database"
  type        = string
  default     = "redis-cloud-only-db"
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

# =============================================================================
# MAINTENANCE CONFIGURATION
# =============================================================================

variable "maintenance_start_hour" {
  description = "Hour when maintenance window starts (0-23)"
  type        = number
  default     = 22

  validation {
    condition     = var.maintenance_start_hour >= 0 && var.maintenance_start_hour <= 23
    error_message = "Maintenance start hour must be between 0 and 23."
  }
}

variable "maintenance_duration" {
  description = "Duration of maintenance window in hours"
  type        = number
  default     = 8

  validation {
    condition     = var.maintenance_duration >= 1 && var.maintenance_duration <= 24
    error_message = "Maintenance duration must be between 1 and 24 hours."
  }
}

variable "maintenance_days" {
  description = "Days of the week for maintenance window"
  type        = list(string)
  default     = ["Tuesday", "Friday"]

  validation {
    condition = alltrue([
      for day in var.maintenance_days : contains(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], day)
    ])
    error_message = "Maintenance days must be valid day names."
  }
}

# =============================================================================
# ALERT CONFIGURATION
# =============================================================================

variable "enable_alerts" {
  description = "Enable database monitoring alerts for Redis Cloud"
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

variable "throughput_alert_threshold_percentage" {
  description = "Throughput alert threshold as percentage of max throughput (0-100)"
  type        = number
  default     = 80
  
  validation {
    condition     = var.throughput_alert_threshold_percentage >= 0 && var.throughput_alert_threshold_percentage <= 100
    error_message = "Throughput alert threshold percentage must be between 0 and 100."
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