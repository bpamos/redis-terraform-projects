# =============================================================================
# REQUIRED VARIABLES
# =============================================================================

variable "subscription_id" {
  description = "ID of the Redis Cloud subscription"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID of the VPC to be peered"
  type        = string
  
  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "AWS account ID must be a 12-digit number."
  }
}

variable "region" {
  description = "AWS region of the VPC"
  type        = string
}

variable "vpc_id" {
  description = "ID of the AWS VPC to be peered"
  type        = string
  
  validation {
    condition     = can(regex("^vpc-", var.vpc_id))
    error_message = "VPC ID must start with 'vpc-'."
  }
}

variable "vpc_cidr" {
  description = "CIDR block of the AWS VPC to be peered"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

variable "route_table_id" {
  description = "ID of the primary AWS route table to update"
  type        = string
  
  validation {
    condition     = can(regex("^rtb-", var.route_table_id))
    error_message = "Route table ID must start with 'rtb-'."
  }
}

variable "peer_cidr_block" {
  description = "CIDR block of the Redis Cloud network to route to"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.peer_cidr_block, 0))
    error_message = "Peer CIDR block must be a valid CIDR block."
  }
}

# =============================================================================
# OPTIONAL CONFIGURATION VARIABLES
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names and tags"
  type        = string
  default     = "redis-peering"
}

variable "activation_wait_time" {
  description = "Time in seconds to wait for Redis Cloud subscription activation"
  type        = number
  default     = 60
  
  validation {
    condition     = var.activation_wait_time >= 30 && var.activation_wait_time <= 300
    error_message = "Activation wait time must be between 30 and 300 seconds."
  }
}

variable "peering_create_timeout" {
  description = "Timeout for creating VPC peering connection"
  type        = string
  default     = "10m"
}

variable "peering_delete_timeout" {
  description = "Timeout for deleting VPC peering connection"
  type        = string
  default     = "10m"
}

variable "auto_accept_peering" {
  description = "Automatically accept the VPC peering connection"
  type        = bool
  default     = true
}

variable "create_route" {
  description = "Whether to create a route in the primary route table"
  type        = bool
  default     = true
}

variable "additional_route_table_ids" {
  description = "Set of additional route table IDs to add Redis Cloud routes to"
  type        = set(string)
  default     = []
  
  validation {
    condition = alltrue([
      for rt_id in var.additional_route_table_ids : can(regex("^rtb-", rt_id))
    ])
    error_message = "All additional route table IDs must start with 'rtb-'."
  }
}

variable "tags" {
  description = "Key-value tags to associate with AWS resources"
  type        = map(string)
  default     = {}
}