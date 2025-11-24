# =============================================================================
# VPC PEERING MESH MODULE VARIABLES
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "region_configs" {
  description = "Map of region configurations with VPC details for peering"
  type = map(object({
    vpc_id                       = string
    vpc_cidr                     = string
    private_route_table_id       = string
    public_route_table_id        = string
  }))
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
