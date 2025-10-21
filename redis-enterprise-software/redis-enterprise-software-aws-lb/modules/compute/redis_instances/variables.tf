# =============================================================================
# REDIS INSTANCES MODULE VARIABLES
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
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

# =============================================================================
# INSTANCE CONFIGURATION
# =============================================================================

variable "node_count" {
  description = "Number of Redis Enterprise nodes"
  type        = number
  validation {
    condition     = var.node_count >= 3 && var.node_count <= 9 && var.node_count % 2 == 1
    error_message = "Node count must be an odd number between 3 and 9."
  }
}

variable "ami_id" {
  description = "AMI ID for Redis Enterprise instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.xlarge"
}

variable "key_name" {
  description = "Name of the AWS key pair"
  type        = string
}

variable "node_root_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 50
}

variable "ebs_encryption_enabled" {
  description = "Enable EBS encryption"
  type        = bool
  default     = true
}

variable "associate_public_ip_address" {
  description = "Associate public IP address with instances"
  type        = bool
  default     = true
}

# =============================================================================
# NETWORKING
# =============================================================================

variable "subnet_ids" {
  description = "List of subnet IDs for instance placement"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for Redis Enterprise instances"
  type        = string
}

# =============================================================================
# USER DATA
# =============================================================================

variable "user_data_base64" {
  description = "Base64 encoded user data script"
  type        = string
}