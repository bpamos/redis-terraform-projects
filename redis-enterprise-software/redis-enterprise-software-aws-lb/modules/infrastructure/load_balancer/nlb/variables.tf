# =============================================================================
# AWS NETWORK LOAD BALANCER VARIABLES
# =============================================================================

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where NLB will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for NLB deployment"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs (for reference)"
  type        = list(string)
}

variable "instance_ids" {
  description = "List of Redis Enterprise instance IDs to target"
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

variable "allow_access_from" {
  description = "List of CIDR blocks allowed to access the load balancer"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Tags to apply to NLB resources"
  type        = map(string)
  default     = {}
}