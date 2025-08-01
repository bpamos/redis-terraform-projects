variable "ec2_application_ip" {
  description = "Public IP of the EC2 instance running the application"
  type        = string
}

variable "redis_cloud_endpoint" {
  description = "Redis Cloud hostname without port"
  type        = string
}

variable "redis_cloud_port" {
  description = "Redis Cloud port"
  type        = string
}

variable "redis_cloud_password" {
  description = "Redis Cloud password"
  type        = string
  sensitive   = true
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key for accessing the EC2 instance"
  type        = string
}

variable "riot_public_ip" {
  description = "Public IP of the EC2 RIOT node for Grafana access"
  type        = string
}

variable "elasticache_endpoint" {
  description = "ElastiCache hostname without port"
  type        = string
}

variable "elasticache_port" {
  description = "ElastiCache port"
  type        = string
  default     = "6379"
}

variable "elasticache_password" {
  description = "ElastiCache password (empty for non-auth clusters)"
  type        = string
  default     = ""
  sensitive   = true
}