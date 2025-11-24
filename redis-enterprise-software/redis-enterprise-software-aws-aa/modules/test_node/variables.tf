# =============================================================================
# TEST NODE MODULE VARIABLES
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Redis testing"
  type        = string
  default     = "t3.small"
}

variable "subnet_id" {
  description = "The ID of the subnet to launch the EC2 instance into"
  type        = string
}

variable "security_group_id" {
  description = "Security group for test node"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to private key file for SSH access"
  type        = string
}

variable "owner" {
  description = "Owner tag for resources"
  type        = string
}

variable "project" {
  description = "Project tag for resources"
  type        = string
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

# Redis Enterprise connection details (optional, for auto-configuration)
variable "redis_endpoint" {
  description = "Redis Enterprise endpoint for testing (optional)"
  type        = string
  default     = ""
}

variable "redis_password" {
  description = "Redis password for testing (optional)"
  type        = string
  default     = ""
  sensitive   = true
}
