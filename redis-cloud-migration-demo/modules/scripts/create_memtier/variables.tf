variable "host" {
  description = "Public IP of EC2 instance"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to private key for SSH"
  type        = string
}

variable "redis_endpoint" {
  description = "Target Redis endpoint for memtier_benchmark"
  type        = string
}
