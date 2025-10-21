# =============================================================================
# USER DATA MODULE VARIABLES
# =============================================================================

variable "platform" {
  description = "Operating system platform"
  type        = string
  validation {
    condition     = contains(["ubuntu", "rhel"], var.platform)
    error_message = "Platform must be 'ubuntu' or 'rhel'."
  }
}

variable "hostname" {
  description = "Hostname for the instance"
  type        = string
}