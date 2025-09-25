variable "name_prefix" {
  type = string
}

variable "ec2_name_suffix" {
  description = "Suffix for EC2 instance name"
  type        = string
  default     = "test-ec2"
}

variable "ami_id" {
  description = "AMI ID to use for EC2"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Redis testing"
  type        = string
  default     = "t3.medium"
}

variable "subnet_id" {
  description = "The ID of the subnet to launch the EC2 instance into"
  type        = string
}

variable "security_group_id" {
  description = "Security group for EC2"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "owner" {
  type = string
}

variable "project" {
  type = string
}

variable "ssh_private_key_path" {
  description = "Path to private key file for SSH access"
  type        = string
}

# Redis Cloud connection details
variable "redis_cloud_endpoint" {
  description = "Redis Cloud endpoint (host:port) for testing"
  type        = string
  default     = ""
}

variable "redis_cloud_password" {
  description = "Redis Cloud password for testing"
  type        = string
  default     = ""
  sensitive   = true
}

