# =============================================================================
# PROJECT CONFIGURATION
# =============================================================================

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "redis-enterprise"

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
  default     = "redis-enterprise-software-aws"

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
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  
  validation {
    condition     = length(var.public_subnet_cidrs) >= 3
    error_message = "At least 3 public subnets are required for Redis Enterprise cluster."
  }
}

variable "private_subnet_cidrs" {
  description = "List of CIDRs for private subnets"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  
  validation {
    condition     = length(var.private_subnet_cidrs) >= 3
    error_message = "At least 3 private subnets are required for Redis Enterprise cluster."
  }
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
# DNS CONFIGURATION
# =============================================================================

variable "dns_hosted_zone_id" {
  description = "Route53 hosted zone ID for DNS records"
  type        = string

  validation {
    condition     = length(var.dns_hosted_zone_id) > 0
    error_message = "DNS hosted zone ID cannot be empty."
  }
}

variable "cluster_fqdn" {
  description = "Cluster name (will be combined with DNS hosted zone to form full FQDN)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.cluster_fqdn)) && length(var.cluster_fqdn) > 0
    error_message = "Cluster name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "create_dns_records" {
  description = "Create DNS A records for Redis Enterprise nodes"
  type        = bool
  default     = true
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

# =============================================================================
# REDIS ENTERPRISE CLUSTER CONFIGURATION
# =============================================================================

variable "platform" {
  description = "Operating system platform for Redis Enterprise nodes. Choose 'ubuntu' for Ubuntu 22.04 LTS or 'rhel' for Red Hat Enterprise Linux 9. Each platform uses appropriate AMI, SSH user, installation scripts, and system configurations."
  type        = string
  default     = "ubuntu"

  validation {
    condition     = contains(["ubuntu", "rhel"], var.platform)
    error_message = "Platform must be either 'ubuntu' or 'rhel'."
  }
}

variable "node_count" {
  description = "Number of Redis Enterprise nodes in the cluster"
  type        = number
  default     = 3

  validation {
    condition     = var.node_count >= 3 && var.node_count <= 9
    error_message = "Node count must be between 3 and 9 for Redis Enterprise cluster."
  }
}

variable "instance_type" {
  description = "EC2 instance type for Redis Enterprise nodes"
  type        = string
  default     = "t3.xlarge"

  validation {
    condition = contains([
      "t3.large", "t3.xlarge", "t3.2xlarge",
      "m5.large", "m5.xlarge", "m5.2xlarge", "m5.4xlarge",
      "c5.large", "c5.xlarge", "c5.2xlarge", "c5.4xlarge",
      "r5.large", "r5.xlarge", "r5.2xlarge", "r5.4xlarge"
    ], var.instance_type)
    error_message = "Instance type must be appropriate for Redis Enterprise workloads."
  }
}

variable "node_root_size" {
  description = "Root EBS volume size in GB for Redis Enterprise nodes"
  type        = number
  default     = 50

  validation {
    condition     = var.node_root_size >= 50 && var.node_root_size <= 1000
    error_message = "Root volume size must be between 50 and 1000 GB."
  }
}

variable "data_volume_size" {
  description = "Size of data EBS volume in GB (should be RAM x 4 for testing)"
  type        = number
  default     = 64

  validation {
    condition     = var.data_volume_size >= 32 && var.data_volume_size <= 16384
    error_message = "Data volume size must be between 32 and 16384 GB."
  }
}

variable "data_volume_type" {
  description = "EBS volume type for data storage"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp3", "gp2", "io1", "io2"], var.data_volume_type)
    error_message = "Data volume type must be one of: gp3, gp2, io1, io2."
  }
}

variable "persistent_volume_size" {
  description = "Size of persistent EBS volume in GB (should be RAM x 4 for testing)"
  type        = number
  default     = 64

  validation {
    condition     = var.persistent_volume_size >= 32 && var.persistent_volume_size <= 16384
    error_message = "Persistent volume size must be between 32 and 16384 GB."
  }
}

variable "persistent_volume_type" {
  description = "EBS volume type for persistent storage"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp3", "gp2", "io1", "io2"], var.persistent_volume_type)
    error_message = "Persistent volume type must be one of: gp3, gp2, io1, io2."
  }
}

variable "ebs_encryption_enabled" {
  description = "Enable EBS volume encryption"
  type        = bool
  default     = true
}

variable "re_download_url" {
  description = "Redis Enterprise download URL - must be provided by user for their desired version"
  type        = string

  validation {
    condition     = length(var.re_download_url) > 0 && can(regex("^https://", var.re_download_url))
    error_message = "Redis Enterprise download URL must be specified and be a valid HTTPS URL. Please provide the download URL for your desired version in terraform.tfvars."
  }
}

variable "cluster_username" {
  description = "Username for Redis Enterprise cluster administration"
  type        = string
  default     = "admin@redis.com"

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.cluster_username))
    error_message = "Cluster username must be a valid email address."
  }
}

variable "cluster_password" {
  description = "Password for Redis Enterprise cluster administration"
  type        = string
  default     = "RedisEnterprise123!"

  validation {
    condition     = length(var.cluster_password) >= 4
    error_message = "Cluster password must be at least 4 characters long."
  }
}

variable "flash_enabled" {
  description = "Enable Redis on Flash (RoF) capability"
  type        = bool
  default     = false
}

variable "rack_awareness" {
  description = "Enable rack/zone awareness for high availability"
  type        = bool
  default     = true
}

# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================

variable "create_sample_database" {
  description = "Create a sample Redis database automatically after cluster setup"
  type        = bool
  default     = true
}

variable "sample_db_name" {
  description = "Name for the sample Redis database"
  type        = string
  default     = "demo"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.sample_db_name)) && length(var.sample_db_name) <= 20
    error_message = "Database name must start with a letter, contain only lowercase letters, numbers, and hyphens, and be 20 characters or less."
  }
}

variable "sample_db_port" {
  description = "Port for the sample Redis database"
  type        = number
  default     = 12000

  validation {
    condition     = var.sample_db_port >= 10000 && var.sample_db_port <= 19999
    error_message = "Database port must be between 10000 and 19999."
  }
}

variable "sample_db_memory" {
  description = "Memory size in MB for the sample Redis database"
  type        = number
  default     = 100

  validation {
    condition     = var.sample_db_memory >= 50 && var.sample_db_memory <= 10000
    error_message = "Database memory must be between 50 and 10000 MB."
  }
}

# =============================================================================
# RESOURCE TAGGING
# =============================================================================

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}