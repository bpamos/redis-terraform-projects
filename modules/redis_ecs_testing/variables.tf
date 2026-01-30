# =============================================================================
# REDIS ECS TESTING MODULE VARIABLES
# =============================================================================

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================

variable "redis_endpoints" {
  description = "Map of region to Redis endpoint configuration"
  type = map(object({
    host = string
    port = number
  }))

  validation {
    condition     = length(var.redis_endpoints) > 0
    error_message = "At least one Redis endpoint must be provided."
  }
}

variable "vpc_config" {
  description = "VPC configuration for each region"
  type = map(object({
    vpc_id     = string
    subnet_ids = list(string)
  }))

  validation {
    condition     = length(var.vpc_config) > 0
    error_message = "At least one VPC configuration must be provided."
  }
}

variable "cluster_prefix" {
  description = "Prefix for ECS cluster and resource names"
  type        = string

  validation {
    condition     = length(var.cluster_prefix) > 0 && length(var.cluster_prefix) <= 30
    error_message = "Cluster prefix must be between 1 and 30 characters."
  }
}

# =============================================================================
# OPTIONAL VARIABLES - ECS Configuration
# =============================================================================

variable "task_cpu" {
  description = "CPU units for ECS task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.task_cpu)
    error_message = "Task CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "task_memory" {
  description = "Memory for ECS task in MB (512, 1024, 2048, etc.)"
  type        = number
  default     = 512

  validation {
    condition     = var.task_memory >= 512 && var.task_memory <= 30720
    error_message = "Task memory must be between 512 and 30720 MB."
  }
}

variable "default_task_count" {
  description = "Default number of tasks to run per service (0 = no cost)"
  type        = number
  default     = 0

  validation {
    condition     = var.default_task_count >= 0 && var.default_task_count <= 100
    error_message = "Task count must be between 0 and 100."
  }
}

variable "test_container_image" {
  description = "Docker image for Redis testing (must have redis-cli)"
  type        = string
  default     = "redis:latest"
}

variable "test_mode" {
  description = "Testing mode: ping, read, write, mixed"
  type        = string
  default     = "ping"

  validation {
    condition     = contains(["ping", "read", "write", "mixed"], var.test_mode)
    error_message = "Test mode must be one of: ping, read, write, mixed."
  }
}

variable "test_interval_seconds" {
  description = "Interval between tests in seconds"
  type        = number
  default     = 5

  validation {
    condition     = var.test_interval_seconds >= 1 && var.test_interval_seconds <= 3600
    error_message = "Test interval must be between 1 and 3600 seconds."
  }
}

variable "custom_command" {
  description = "Custom command to run in container (overrides default)"
  type        = list(string)
  default     = null
}

variable "redis_password" {
  description = "Redis AUTH password (optional). Set this if your Redis endpoint requires authentication."
  type        = string
  default     = null
  sensitive   = true
}

variable "app_environment" {
  description = "Additional environment variables to pass to containers (e.g., OPERATIONS_PER_SECOND, KEY_PREFIX)"
  type        = map(string)
  default     = {}
}

# =============================================================================
# OPTIONAL VARIABLES - Load Testing
# =============================================================================

variable "enable_load_testing" {
  description = "Create additional task definition for redis-benchmark load testing"
  type        = bool
  default     = false
}

variable "load_test_task_cpu" {
  description = "CPU units for load testing task"
  type        = number
  default     = 512
}

variable "load_test_task_memory" {
  description = "Memory for load testing task in MB"
  type        = number
  default     = 1024
}

variable "load_test_connections" {
  description = "Number of concurrent connections for redis-benchmark"
  type        = number
  default     = 50
}

variable "load_test_requests" {
  description = "Total number of requests for redis-benchmark"
  type        = number
  default     = 100000
}

# =============================================================================
# OPTIONAL VARIABLES - Observability
# =============================================================================

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for ECS clusters"
  type        = bool
  default     = true
}

variable "enable_ecs_exec" {
  description = "Enable ECS Exec for debugging (aws ecs execute-command)"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 7

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180,
      365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch Logs retention period."
  }
}

# =============================================================================
# OPTIONAL VARIABLES - Tagging
# =============================================================================

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
