# =============================================================================
# DATABASE MANAGEMENT MODULE VARIABLES
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names and cluster FQDN"
  type        = string
}

variable "platform" {
  description = "Operating system platform"
  type        = string
  validation {
    condition     = contains(["ubuntu", "rhel"], var.platform)
    error_message = "Platform must be 'ubuntu' or 'rhel'."
  }
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for connecting to instances"
  type        = string
}

variable "hosted_zone_name" {
  description = "Route53 hosted zone name (e.g., example.com)"
  type        = string
}

# =============================================================================
# INSTANCE INFORMATION
# =============================================================================

variable "public_ips" {
  description = "List of public IP addresses"
  type        = list(string)
}

# =============================================================================
# CLUSTER DEPENDENCIES
# =============================================================================

variable "cluster_verification_id" {
  description = "Cluster verification resource ID to ensure proper ordering"
  type        = string
}

variable "cluster_username" {
  description = "Redis Enterprise cluster admin username"
  type        = string
}

variable "cluster_password" {
  description = "Redis Enterprise cluster admin password"
  type        = string
  sensitive   = true
}

# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================

variable "create_sample_database" {
  description = "Create a sample Redis database for testing"
  type        = bool
  default     = true
}

variable "sample_db_name" {
  description = "Name of the sample database"
  type        = string
  default     = "demo"
}

variable "sample_db_port" {
  description = "Port for the sample database"
  type        = number
  default     = 12000
  validation {
    condition     = var.sample_db_port >= 10000 && var.sample_db_port <= 19999
    error_message = "Sample database port must be between 10000 and 19999."
  }
}

variable "sample_db_memory" {
  description = "Memory allocation for sample database in MB"
  type        = number
  default     = 100
  validation {
    condition     = var.sample_db_memory >= 100 && var.sample_db_memory <= 10000
    error_message = "Sample database memory must be between 100MB and 10000MB."
  }
}