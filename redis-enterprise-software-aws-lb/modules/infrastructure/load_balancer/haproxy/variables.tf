# =============================================================================
# HAPROXY LOAD BALANCER VARIABLES
# =============================================================================

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where HAProxy will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for HAProxy deployment"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs (for reference)"
  type        = list(string)
}

variable "instance_ids" {
  description = "List of Redis Enterprise instance IDs"
  type        = list(string)
}

variable "private_ips" {
  description = "List of Redis Enterprise instance private IPs"
  type        = list(string)
}

variable "public_ips" {
  description = "List of Redis Enterprise instance public IPs"
  type        = list(string)
}

variable "key_name" {
  description = "EC2 key pair name for HAProxy instances"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for HAProxy configuration"
  type        = string
}

variable "platform" {
  description = "Platform for HAProxy instances (ubuntu or rhel)"
  type        = string
  default     = "ubuntu"

  validation {
    condition     = contains(["ubuntu", "rhel"], var.platform)
    error_message = "Platform must be either 'ubuntu' or 'rhel'."
  }
}

variable "instance_type" {
  description = "EC2 instance type for HAProxy load balancers"
  type        = string
  default     = "t3.medium"
}

variable "allow_access_from" {
  description = "List of CIDR blocks allowed to access the load balancer"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Tags to apply to HAProxy resources"
  type        = map(string)
  default     = {}
}