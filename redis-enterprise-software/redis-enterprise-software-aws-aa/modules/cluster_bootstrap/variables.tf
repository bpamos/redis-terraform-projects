# =============================================================================
# CLUSTER BOOTSTRAP MODULE VARIABLES
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names and cluster FQDN"
  type        = string
}

variable "node_count" {
  description = "Number of Redis Enterprise nodes"
  type        = number
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
# CLUSTER CONFIGURATION
# =============================================================================

variable "cluster_username" {
  description = "Redis Enterprise cluster admin username"
  type        = string
}

variable "cluster_password" {
  description = "Redis Enterprise cluster admin password"
  type        = string
  sensitive   = true
}

variable "rack_awareness" {
  description = "Enable rack awareness for high availability"
  type        = bool
  default     = true
}

variable "flash_enabled" {
  description = "Enable Redis on Flash (RoF)"
  type        = bool
  default     = false
}

# =============================================================================
# INSTANCE INFORMATION
# =============================================================================

variable "instance_ids" {
  description = "List of EC2 instance IDs"
  type        = list(string)
}

variable "public_ips" {
  description = "List of public IP addresses"
  type        = list(string)
}

variable "private_ips" {
  description = "List of private IP addresses"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones where instances are placed"
  type        = list(string)
}

# =============================================================================
# INSTALLATION DEPENDENCIES
# =============================================================================

variable "installation_completion_ids" {
  description = "Installation completion resource IDs to ensure proper ordering"
  type        = list(string)
}