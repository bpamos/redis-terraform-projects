# =============================================================================
# STORAGE MODULE VARIABLES
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names (computed from user_prefix-cluster_name)"
  type        = string
}

variable "user_prefix" {
  description = "User identifier prefix"
  type        = string
}

variable "cluster_name" {
  description = "Cluster name suffix"
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

variable "node_count" {
  description = "Number of Redis Enterprise nodes"
  type        = number
}

variable "subnet_ids" {
  description = "List of subnet IDs where volumes will be created"
  type        = list(string)
}

variable "instance_ids" {
  description = "List of EC2 instance IDs to attach volumes to"
  type        = list(string)
}

# =============================================================================
# EBS VOLUME CONFIGURATION
# =============================================================================

variable "data_volume_size" {
  description = "Size of the data volume in GB"
  type        = number
  default     = 64
}

variable "data_volume_type" {
  description = "Type of the data volume"
  type        = string
  default     = "gp3"
}

variable "persistent_volume_size" {
  description = "Size of the persistent volume in GB"
  type        = number
  default     = 64
}

variable "persistent_volume_type" {
  description = "Type of the persistent volume"
  type        = string
  default     = "gp3"
}

variable "ebs_encryption_enabled" {
  description = "Enable EBS encryption"
  type        = bool
  default     = true
}