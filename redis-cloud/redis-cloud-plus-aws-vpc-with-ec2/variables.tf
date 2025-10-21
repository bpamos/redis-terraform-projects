# =============================================================================
# PROJECT CONFIGURATION
# =============================================================================

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "redis-vpc-demo"

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
  default     = "redis-cloud-vpc-demo"

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

variable "availability_zones" {
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
  description = "Credit card type for Redis Cloud payment (only required for credit-card payment method)"
  type        = string
  default     = "Visa"

  validation {
    condition     = contains(["Visa", "Mastercard", "American Express", "Discover"], var.credit_card_type)
    error_message = "Credit card type must be Visa, Mastercard, American Express, or Discover."
  }
}

variable "credit_card_last_four" {
  description = "Last four digits of the credit card for Redis Cloud subscription (only required for credit-card payment method)"
  type        = string
  default     = ""

  validation {
    condition     = var.credit_card_last_four == "" || can(regex("^[0-9]{4}$", var.credit_card_last_four))
    error_message = "Credit card last four must be empty or exactly 4 digits."
  }
}

variable "subscription_name" {
  description = "Name for the Redis Cloud subscription"
  type        = string
  default     = "redis-vpc-subscription"
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
# CREATION PLAN CONFIGURATION (for subscription setup)
# =============================================================================

variable "initial_dataset_size_in_gb" {
  description = "Initial dataset size in GB for subscription creation plan"
  type        = number
  default     = 1

  validation {
    condition     = var.initial_dataset_size_in_gb > 0
    error_message = "Initial dataset size must be greater than 0 GB."
  }
}

variable "initial_database_quantity" {
  description = "Initial number of databases for subscription creation plan"
  type        = number
  default     = 2

  validation {
    condition     = var.initial_database_quantity >= 1
    error_message = "Initial database quantity must be at least 1."
  }
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

  validation {
    condition     = contains(["operations-per-second", "number-of-shards"], var.initial_throughput_by)
    error_message = "Initial throughput measurement must be 'operations-per-second' or 'number-of-shards'."
  }
}

variable "initial_throughput_value" {
  description = "Initial throughput value for subscription creation plan"
  type        = number
  default     = 2000

  validation {
    condition     = var.initial_throughput_value > 0
    error_message = "Initial throughput value must be greater than 0."
  }
}

variable "initial_modules" {
  description = "Initial modules for subscription creation plan"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for module in var.initial_modules : contains([
        "RedisJSON", "RedisTimeSeries", "RediSearch", "RedisBloom"
      ], module)
    ])
    error_message = "All initial modules must be valid Redis Enterprise modules."
  }
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
  description = "Redis version to deploy. If omitted, uses Redis Cloud default"
  type        = string
  default     = null

  validation {
    condition = var.redis_version == null || contains([
      "6.0", "6.2", "7.0", "7.2", "7.4"
    ], var.redis_version)
    error_message = "Redis version must be a valid supported version or null for default."
  }
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
      for module in var.modules_enabled : contains(["RedisJSON", "RedisTimeSeries", "RediSearch", "RedisBloom"], module)
    ])
    error_message = "All modules must be valid Redis Enterprise modules."
  }
}

variable "database_name" {
  description = "Name of the Redis database"
  type        = string
  default     = "redis-vpc-db"
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

# =============================================================================
# EC2 TEST INSTANCE CONFIGURATION
# =============================================================================

variable "enable_ec2_testing" {
  description = "Whether to deploy EC2 instance for Redis testing"
  type        = bool
  default     = true
}

variable "ec2_instance_type" {
  description = "EC2 instance type for Redis testing"
  type        = string
  default     = "t3.medium"

  validation {
    condition     = can(regex("^[a-z][0-9]+[a-z]*\\.[a-z0-9]+$", var.ec2_instance_type))
    error_message = "EC2 instance type must be a valid AWS instance type (e.g., t3.medium, m5.large)."
  }
}

variable "ec2_name_suffix" {
  description = "Suffix for EC2 instance name (will be: name_prefix-suffix)"
  type        = string
  default     = "test-ec2"
}

variable "ec2_key_name" {
  description = "SSH key pair name for EC2 instance access"
  type        = string
  default     = ""
}

variable "ec2_ssh_private_key_path" {
  description = "Path to private SSH key file for EC2 access"
  type        = string
  default     = ""
}


variable "enable_observability" {
  description = "Whether to install Prometheus and Grafana for Redis Cloud monitoring"
  type        = bool
  default     = false
}

variable "allow_ssh_from" {
  description = "List of CIDR blocks allowed to SSH to EC2 instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}


# =============================================================================
# RESOURCE TAGGING
# =============================================================================

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

# =============================================================================
# ADVANCED SUBSCRIPTION CONFIGURATION
# =============================================================================

variable "allowlist_security_group_ids" {
  description = "Set of security groups that are allowed to access the databases associated with this subscription. Only available when running on your own cloud account (cloud_account_id != 1)"
  type        = list(string)
  default     = null
}

variable "allowlist_cidrs" {
  description = "Set of CIDR ranges that are allowed to access the databases associated with this subscription. Only available when running on your own cloud account (cloud_account_id != 1)"
  type        = list(string)
  default     = null
}

variable "customer_managed_key_resource_name" {
  description = "The resource name of the customer managed key as defined by the cloud provider (e.g., projects/PROJECT_ID/locations/LOCATION/keyRings/KEY_RING/cryptoKeys/KEY_NAME)"
  type        = string
  default     = null
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

variable "enable_tls" {
  description = "Enable TLS encryption for client connections"
  type        = bool
  default     = false
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