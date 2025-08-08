variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "node_count" {
  description = "Number of Redis Enterprise nodes"
  type        = number
}

variable "instance_type" {
  description = "EC2 instance type for Redis Enterprise nodes"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for Redis Enterprise nodes"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key file"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where cluster will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for Redis Enterprise nodes"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for Redis Enterprise cluster"
  type        = string
}

variable "node_root_size" {
  description = "Root EBS volume size in GB"
  type        = number
}

variable "data_volume_size" {
  description = "Size of data EBS volume in GB (should be RAM x 4 for testing)"
  type        = number
}

variable "data_volume_type" {
  description = "EBS volume type for data storage"
  type        = string
  default     = "gp3"
}

variable "persistent_volume_size" {
  description = "Size of persistent EBS volume in GB (should be RAM x 4 for testing)"
  type        = number
}

variable "persistent_volume_type" {
  description = "EBS volume type for persistent storage"
  type        = string
  default     = "gp3"
}

variable "ebs_encryption_enabled" {
  description = "Enable EBS volume encryption"
  type        = bool
  default     = true
}

variable "platform" {
  description = "Operating system platform for Redis Enterprise nodes"
  type        = string
  default     = "ubuntu"

  validation {
    condition     = contains(["ubuntu", "rhel"], var.platform)
    error_message = "Platform must be either 'ubuntu' or 'rhel'."
  }
}

variable "re_download_url" {
  description = "Redis Enterprise download URL - must be provided by user for their desired version"
  type        = string
  
  validation {
    condition     = length(var.re_download_url) > 0
    error_message = "Redis Enterprise download URL must be specified. Please provide the download URL for your desired version in terraform.tfvars."
  }
}

variable "cluster_username" {
  description = "Redis Enterprise cluster admin username"
  type        = string
}

variable "cluster_password" {
  description = "Redis Enterprise cluster admin password"
  type        = string
}

variable "flash_enabled" {
  description = "Enable Redis on Flash"
  type        = bool
}

variable "rack_awareness" {
  description = "Enable rack awareness"
  type        = bool
}

variable "cluster_fqdn" {
  description = "Cluster name (will be combined with DNS hosted zone to form full FQDN)"
  type        = string
}

variable "dns_hosted_zone_id" {
  description = "Route53 hosted zone ID for DNS records"
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

# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================

variable "create_sample_database" {
  description = "Create a sample Redis database automatically"
  type        = bool
  default     = true
}

variable "sample_db_name" {
  description = "Name for the sample Redis database"
  type        = string
  default     = "demo"
}

variable "sample_db_port" {
  description = "Port for the sample Redis database"
  type        = number
  default     = 12000
}

variable "sample_db_memory" {
  description = "Memory size in MB for the sample Redis database"
  type        = number
  default     = 100
}