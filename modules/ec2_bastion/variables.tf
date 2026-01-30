# =============================================================================
# EC2 BASTION MODULE VARIABLES
# =============================================================================

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet to launch the EC2 instance into"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name for EC2 instance access"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to private key file for SSH access"
  type        = string
  default     = ""
}

variable "owner" {
  description = "Owner tag for resources"
  type        = string
}

variable "project" {
  description = "Project tag for resources"
  type        = string
}

# =============================================================================
# OPTIONAL VARIABLES - INSTANCE CONFIGURATION
# =============================================================================

variable "instance_type" {
  description = "EC2 instance type for bastion/testing node"
  type        = string
  default     = "t3.small"
}

variable "associate_public_ip" {
  description = "Whether to associate a public IP address with the instance"
  type        = bool
  default     = true
}

# =============================================================================
# OPTIONAL VARIABLES - NETWORKING
# =============================================================================

variable "vpc_id" {
  description = "VPC ID (required if security_group_id is not provided)"
  type        = string
  default     = ""
}

variable "security_group_id" {
  description = "Security group ID for bastion (if empty, a new one will be created)"
  type        = string
  default     = ""
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH to bastion (only used if security_group_id is empty)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# =============================================================================
# OPTIONAL VARIABLES - REDIS CONFIGURATION
# =============================================================================

variable "redis_endpoints" {
  description = "Map of Redis endpoints for auto-configuration. Example: { demo = { endpoint = 'host:port', password = 'secret' } }"
  type = map(object({
    endpoint = string
    password = string
  }))
  default   = {}
  sensitive = true
}

# =============================================================================
# OPTIONAL VARIABLES - TOOL INSTALLATION
# =============================================================================

variable "install_kubectl" {
  description = "Install kubectl for Kubernetes cluster management"
  type        = bool
  default     = false
}

variable "install_aws_cli" {
  description = "Install AWS CLI v2 for AWS resource management"
  type        = bool
  default     = false
}

variable "install_docker" {
  description = "Install Docker for container operations"
  type        = bool
  default     = false
}

# =============================================================================
# OPTIONAL VARIABLES - EKS INTEGRATION
# =============================================================================

variable "eks_cluster_name" {
  description = "EKS cluster name for kubectl configuration (requires install_kubectl=true)"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region for EKS cluster and AWS CLI configuration"
  type        = string
  default     = ""
}

# =============================================================================
# OPTIONAL VARIABLES - TAGGING
# =============================================================================

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
