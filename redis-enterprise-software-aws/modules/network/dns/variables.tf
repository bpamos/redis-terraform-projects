variable "dns_hosted_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}

variable "cluster_fqdn" {
  description = "Fully Qualified Domain Name for the Redis Enterprise cluster (must match the cluster FQDN)"
  type        = string
}

variable "create_dns_records" {
  description = "Whether to create DNS records"
  type        = bool
  default     = true
}

variable "node_count" {
  description = "Number of Redis Enterprise nodes"
  type        = number
}

variable "public_ips" {
  description = "List of public IP addresses for Redis Enterprise nodes"
  type        = list(string)
}

variable "private_ips" {
  description = "List of private IP addresses for Redis Enterprise nodes"
  type        = list(string)
}


variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "owner" {
  description = "Owner of the infrastructure"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}