# =============================================================================
# PROJECT CONFIGURATION
# =============================================================================

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "riot-tooling"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.name_prefix)) && length(var.name_prefix) <= 20
    error_message = "Name prefix must start with a letter, contain only lowercase letters, numbers, and hyphens, and be 20 characters or less."
  }
}

variable "owner" {
  description = "Owner of the infrastructure"
  type        = string

  validation {
    condition     = length(var.owner) > 0 && length(var.owner) <= 50
    error_message = "Owner must be a non-empty string with 50 characters or less."
  }
}

variable "project" {
  description = "Project or environment name"
  type        = string
  default     = "riot-tooling-only"

  validation {
    condition     = length(var.project) > 0 && length(var.project) <= 50
    error_message = "Project must be a non-empty string with 50 characters or less."
  }
}

# =============================================================================
# AWS INFRASTRUCTURE
# =============================================================================

variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-west-2"
  
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be in the format like us-west-2, us-east-1, etc."
  }
}

# =============================================================================
# VPC NETWORKING
# =============================================================================

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  
  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least 2 public subnets are required for high availability."
  }
}

variable "private_subnet_cidrs" {
  description = "List of CIDRs for private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
  
  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least 2 private subnets are required for high availability."
  }
}

variable "azs" {
  description = "Availability zones for subnet deployment"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

# =============================================================================
# SECURITY CONFIGURATION
# =============================================================================

variable "allow_ssh_from" {
  description = "List of CIDRs allowed to SSH into EC2 instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for cidr in var.allow_ssh_from : can(cidrhost(cidr, 0))
    ])
    error_message = "All SSH CIDR blocks must be valid IPv4 CIDR blocks."
  }
}

# =============================================================================
# EC2 CONFIGURATION
# =============================================================================

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
  
  validation {
    condition     = length(var.key_name) > 0
    error_message = "EC2 key pair name cannot be empty."
  }
}

variable "ssh_private_key_path" {
  description = "Path to the private key file for SSH access"
  type        = string
  
  validation {
    condition     = length(var.ssh_private_key_path) > 0 && can(regex("\\.(pem|key)$", var.ssh_private_key_path))
    error_message = "SSH private key path must be provided and end with .pem or .key."
  }
}

variable "riot_instance_type" {
  description = "EC2 instance type for RIOT server (affects Redis OSS memory capacity)"
  type        = string
  default     = "t3.xlarge"
}

variable "aws_account_id" {
  description = "AWS Account ID for VPC peering"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "AWS account ID must be a 12-digit number."
  }
}

variable "riotx_version" {
  description = "Version of RIOT-X to install"
  type        = string
  default     = "3.6.3"
}

variable "enable_observability" {
  description = "Whether to install Prometheus and Grafana"
  type        = bool
  default     = true
}