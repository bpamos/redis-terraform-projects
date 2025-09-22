# =============================================================================
# REDIS CLOUD SUBSCRIPTION VARIABLES
# =============================================================================

variable "rediscloud_api_key" {
  description = "Redis Cloud API key"
  type        = string
}

variable "rediscloud_secret_key" {
  description = "Redis Cloud API secret"
  type        = string
}

variable "payment_method" {
  description = "Payment method for Redis Cloud subscription"
  type        = string
  default     = "credit-card"
  
  validation {
    condition     = contains(["credit-card", "marketplace"], var.payment_method)
    error_message = "Payment method must be either 'credit-card' or 'marketplace'."
  }
}

variable "credit_card_type" {
  description = "Credit card type to use for Redis Cloud payment (e.g., Visa, Mastercard). Only required when payment_method is 'credit-card'."
  type        = string
  default     = "Visa"
}

variable "credit_card_last_four" {
  description = "Last four digits of the credit card to use for Redis Cloud subscription. Only required when payment_method is 'credit-card'."
  type        = string
  default     = ""
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
  description = "Cloud account identifier for Redis Cloud subscription"
  type        = number
  default     = 1

  validation {
    condition     = var.cloud_account_id >= 1
    error_message = "Cloud account ID must be 1 or greater."
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
  description = "Preferred availability zones for Redis Cloud deployment"
  type        = list(string)
  default     = []
}

# =============================================================================
# CREATION PLAN CONFIGURATION
# =============================================================================

variable "initial_dataset_size_in_gb" {
  description = "Initial dataset size in GB for subscription creation plan"
  type        = number
  default     = 1
}

variable "initial_database_quantity" {
  description = "Initial number of databases for subscription creation plan"
  type        = number
  default     = 2
}

variable "initial_replication" {
  description = "Initial replication setting for subscription creation plan"
  type        = bool
  default     = false
}

variable "initial_throughput_by" {
  description = "Initial throughput measurement method for creation plan"
  type        = string
  default     = "operations-per-second"
}

variable "initial_throughput_value" {
  description = "Initial throughput value for subscription creation plan"
  type        = number
  default     = 2000
}

variable "initial_modules" {
  description = "Initial modules for subscription creation plan"
  type        = list(string)
  default     = []
}

# =============================================================================
# MAINTENANCE CONFIGURATION
# =============================================================================

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