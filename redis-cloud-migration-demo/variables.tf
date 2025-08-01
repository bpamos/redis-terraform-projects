# =============================================================================
# PROJECT CONFIGURATION
# =============================================================================

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "redis-demo"

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

variable "aws_account_id" {
  description = "AWS Account ID for Redis Cloud VPC peering"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "AWS account ID must be a 12-digit number."
  }
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
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  
  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least 2 public subnets are required for high availability."
  }
}

variable "private_subnet_cidrs" {
  description = "List of CIDRs for private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
  
  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least 2 private subnets are required for high availability."
  }
}

variable "azs" {
  description = "Availability zones for subnet deployment"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "peer_cidr_block" {
  description = "The Redis Cloud networking CIDR block to route into AWS VPC"
  type        = string
  default     = "10.42.0.0/24"

  validation {
    condition     = can(cidrhost(var.peer_cidr_block, 0))
    error_message = "Peer CIDR block must be a valid IPv4 CIDR block."
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

variable "riot_instance_type" {
  description = "EC2 instance type for RIOT server (affects Redis OSS memory capacity)"
  type        = string
  default     = "t3.xlarge"
}

variable "application_instance_type" {
  description = "EC2 instance type for application server"
  type        = string
  default     = "t3.medium"
}

# =============================================================================
# ELASTICACHE CONFIGURATION
# =============================================================================

variable "node_type" {
  description = "ElastiCache instance type"
  type        = string
  default     = "cache.t3.micro"
}

variable "standalone_replicas" {
  description = "Number of replicas for standalone Redis"
  type        = number
  default     = 0

  validation {
    condition     = var.standalone_replicas >= 0 && var.standalone_replicas <= 5
    error_message = "Standalone replicas must be between 0 and 5."
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
  default     = "redis-migration-subscription"
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
  default     = "redis-migration-db"
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