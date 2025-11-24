variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "allow_ssh_from" {
  description = "List of CIDRs allowed to SSH and access Redis Enterprise UI"
  type        = list(string)
}

variable "peer_region_cidrs" {
  description = "List of VPC CIDRs from other regions for Active-Active cluster communication"
  type        = list(string)
  default     = []
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