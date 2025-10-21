# =============================================================================
# OBSERVABILITY MODULE VARIABLES
# =============================================================================

variable "redis_cloud_endpoint" {
  description = "Redis Cloud endpoint for Prometheus scraping"
  type        = string
}

variable "instance_id" {
  description = "EC2 instance ID for observability setup"
  type        = string
}

variable "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for instance access"
  type        = string
}

variable "depends_on_resources" {
  description = "Resources this module depends on"
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}