# =============================================================================
# AMI SELECTION MODULE VARIABLES
# =============================================================================

variable "platform" {
  description = "Operating system platform"
  type        = string
  validation {
    condition     = contains(["ubuntu", "rhel"], var.platform)
    error_message = "Platform must be 'ubuntu' or 'rhel'."
  }
}