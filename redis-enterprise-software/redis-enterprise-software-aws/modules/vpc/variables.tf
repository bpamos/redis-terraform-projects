# =============================================================================
# REQUIRED VARIABLES
# =============================================================================

variable "name_prefix" {
  description = "Prefix for naming AWS VPC resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)

  validation {
    condition = alltrue([
      for cidr in var.public_subnet_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All public subnet CIDRs must be valid CIDR blocks."
  }
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)

  validation {
    condition = alltrue([
      for cidr in var.private_subnet_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All private subnet CIDRs must be valid CIDR blocks."
  }
}

variable "azs" {
  description = "List of availability zones for subnet placement"
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 1
    error_message = "At least one availability zone must be specified."
  }
}

# =============================================================================
# TAGGING VARIABLES
# =============================================================================

variable "tags" {
  description = "Key-value tags to apply to all VPC resources"
  type        = map(string)
  default     = {}
}

variable "owner" {
  description = "Owner tag for resources"
  type        = string
  default     = ""
}

variable "project" {
  description = "Project name tag for resources"
  type        = string
  default     = ""
}