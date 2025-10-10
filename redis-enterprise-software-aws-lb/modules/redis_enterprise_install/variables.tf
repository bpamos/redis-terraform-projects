# =============================================================================
# REDIS ENTERPRISE INSTALL MODULE VARIABLES
# =============================================================================

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

variable "re_download_url" {
  description = "Redis Enterprise download URL"
  type        = string
  validation {
    condition     = length(var.re_download_url) > 0 && can(regex("^https://", var.re_download_url))
    error_message = "Redis Enterprise download URL must be specified and be a valid HTTPS URL."
  }
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for connecting to instances"
  type        = string
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

# =============================================================================
# STORAGE DEPENDENCIES
# =============================================================================

variable "data_volume_attachment_ids" {
  description = "List of data volume attachment IDs"
  type        = list(string)
}

variable "persistent_volume_attachment_ids" {
  description = "List of persistent volume attachment IDs"
  type        = list(string)
}