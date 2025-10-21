variable "rediscloud_api_key" {
  description = "Redis Cloud API key"
  type        = string
}

variable "rediscloud_secret_key" {
  description = "Redis Cloud API secret"
  type        = string
}

variable "aws_region" {
  description = "AWS region for the Terraform AWS provider"
  type        = string
  default     = "us-west-2"
}

variable "credit_card_type" {
  description = "Credit card type to use for Redis Cloud payment (e.g., Visa, Mastercard)"
  type        = string
  default     = "Visa"
}

variable "credit_card_last_four" {
  description = "Last four digits of the credit card to use for Redis Cloud subscription"
  type        = string
}

variable "subscription_name" {
  description = "Name for the Redis Cloud subscription"
  type        = string
  default     = "my-redis-subscription"
}

variable "memory_storage" {
  description = "Memory storage option for Redis Cloud subscription"
  type        = string
  default     = "ram"
  
  validation {
    condition     = contains(["ram", "ram-and-flash"], var.memory_storage)
    error_message = "Memory storage must be either 'ram' or 'ram-and-flash'."
  }
}

variable "redis_version" {
  description = "Version of Redis to use (e.g., 7.2)"
  type        = string
  default     = "7.2"
}

variable "cloud_provider" {
  description = "Cloud provider to use for Redis Cloud (AWS only)"
  type        = string
  default     = "AWS"
  
  validation {
    condition     = var.cloud_provider == "AWS"
    error_message = "Cloud provider must be AWS."
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

variable "rediscloud_region" {
  description = "Cloud provider region for Redis deployment"
  type        = string
  default     = "us-west-2"
}

variable "multi_az" {
  description = "Deploy Redis across multiple availability zones"
  type        = bool
  default     = true
}

variable "networking_deployment_cidr" {
  description = "CIDR block used for Redis Cloud networking deployment"
  type        = string
  default     = "10.42.0.0/24"
}

variable "preferred_azs" {
  description = "Preferred availability zones for Redis Cloud deployment. Leave empty to let Redis Cloud auto-select optimal zones."
  type        = list(string)
  default     = []
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

variable "database_quantity" {
  description = "Number of databases to create in the subscription"
  type        = number
  default     = 1
}

variable "replication" {
  description = "Whether to enable replication"
  type        = bool
  default     = true
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

variable "maintenance_start_hour" {
  description = "Hour of the day when maintenance window starts (0–23)"
  type        = number
  default     = 22
  
  validation {
    condition     = var.maintenance_start_hour >= 0 && var.maintenance_start_hour <= 23
    error_message = "Maintenance start hour must be between 0 and 23."
  }
}

variable "maintenance_duration" {
  description = "Duration of the maintenance window in hours"
  type        = number
  default     = 8
  
  validation {
    condition     = var.maintenance_duration >= 1 && var.maintenance_duration <= 24
    error_message = "Maintenance duration must be between 1 and 24 hours."
  }
}

variable "maintenance_days" {
  description = "Days of the week for the maintenance window"
  type        = list(string)
  default     = ["Tuesday", "Friday"]
  
  validation {
    condition = alltrue([
      for day in var.maintenance_days : contains(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], day)
    ])
    error_message = "Maintenance days must be valid day names (Monday, Tuesday, etc.)."
  }
}

variable "database_name" {
  description = "Name of the Redis database"
  type        = string
  default     = "redis-cloud-db"
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

variable "tags" {
  description = "Key-value tags to associate with resources"
  type        = map(string)
  default     = {}
}

variable "modules" {
  description = "List of Redis modules to enable (e.g., RedisJSON, RedisTimeSeries, RediSearch)"
  type        = list(string)
  default     = ["RedisJSON"]
  
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

variable "throughput_alert_threshold_percentage" {
  description = "Throughput alert threshold as percentage of max throughput (0-100)"
  type        = number
  default     = 80
  
  validation {
    condition     = var.throughput_alert_threshold_percentage >= 0 && var.throughput_alert_threshold_percentage <= 100
    error_message = "Throughput alert threshold percentage must be between 0 and 100."
  }
}