variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ElastiCache (must be in private subnets)"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group to attach to ElastiCache"
  type        = string
}

variable "node_type" {
  description = "ElastiCache instance type"
  type        = string
  default     = "cache.t3.micro"
}

variable "replicas" {
  description = "Number of read replicas (0 = primary only)"
  type        = number
  default     = 0
}

variable "owner" {
  description = "Owner tag"
  type        = string
}

variable "project" {
  description = "Project tag"
  type        = string
}

variable "replication_group_suffix" {
  description = "Suffix to make replication group ID unique"
  type        = string
}