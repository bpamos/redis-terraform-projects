variable "ec2_public_ip" {
  description = "The public IP address of the EC2 instance running RIOTX."
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to the private SSH key used to access the RIOTX EC2 instance."
  type        = string
}

variable "elasticache_endpoint" {
  description = "Primary endpoint for the ElastiCache Redis (standalone) source."
  type        = string
}

variable "rediscloud_private_endpoint" {
  description = "Private endpoint for the Redis Cloud target database."
  type        = string
}

variable "rediscloud_password" {
  description = "Password for accessing the Redis Cloud database."
  type        = string
  sensitive   = true
}

# Optional configuration variables
variable "replication_mode" {
  description = "RIOT-X replication mode (LIVE, STREAM, or SNAPSHOT)"
  type        = string
  default     = "LIVE"
  
  validation {
    condition     = contains(["LIVE", "STREAM", "SNAPSHOT"], var.replication_mode)
    error_message = "Replication mode must be one of: LIVE, STREAM, SNAPSHOT."
  }
}

variable "enable_metrics" {
  description = "Enable RIOT-X metrics collection"
  type        = bool
  default     = true
}

variable "metrics_port" {
  description = "Port for RIOT-X metrics endpoint"
  type        = number
  default     = 8080
}

variable "log_keys" {
  description = "Enable detailed key logging in RIOT-X"
  type        = bool
  default     = true
}
