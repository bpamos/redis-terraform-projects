# =============================================================================
# REQUIRED VARIABLES
# =============================================================================

variable "name_prefix" {
  description = "Prefix for naming security groups and resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where security groups will be created"
  type        = string
  
  validation {
    condition     = can(regex("^vpc-", var.vpc_id))
    error_message = "VPC ID must start with 'vpc-'."
  }
}

# =============================================================================
# ACCESS CONTROL VARIABLES
# =============================================================================

variable "enable_ssh_access" {
  description = "Enable SSH access to EC2 instances"
  type        = bool
  default     = true
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed SSH access to EC2 instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  
  validation {
    condition = alltrue([
      for cidr in var.ssh_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All SSH CIDR blocks must be valid CIDR notation."
  }
}

variable "enable_observability_access" {
  description = "Enable access to observability tools (Grafana, Prometheus)"
  type        = bool
  default     = true
}

variable "observability_cidr_blocks" {
  description = "CIDR blocks allowed access to observability dashboards"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  
  validation {
    condition = alltrue([
      for cidr in var.observability_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All observability CIDR blocks must be valid CIDR notation."
  }
}

variable "enable_riotx_metrics" {
  description = "Enable access to RIOT-X metrics endpoint"
  type        = bool
  default     = true
}

variable "riotx_metrics_port" {
  description = "Port for RIOT-X metrics endpoint"
  type        = number
  default     = 8080
  
  validation {
    condition     = var.riotx_metrics_port > 0 && var.riotx_metrics_port <= 65535
    error_message = "RIOT-X metrics port must be between 1 and 65535."
  }
}

variable "metrics_cidr_blocks" {
  description = "CIDR blocks allowed access to metrics endpoints"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  
  validation {
    condition = alltrue([
      for cidr in var.metrics_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All metrics CIDR blocks must be valid CIDR notation."
  }
}

variable "enable_redis_oss_access" {
  description = "Enable external access to Redis OSS on RIOT EC2 (for testing)"
  type        = bool
  default     = false
}

variable "redis_oss_cidr_blocks" {
  description = "CIDR blocks allowed access to Redis OSS for testing"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for cidr in var.redis_oss_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All Redis OSS CIDR blocks must be valid CIDR notation."
  }
}

# =============================================================================
# APPLICATION ACCESS VARIABLES
# =============================================================================

variable "enable_flask_access" {
  description = "Enable access to Flask application"
  type        = bool
  default     = true
}

variable "flask_port" {
  description = "Port for Flask application"
  type        = number
  default     = 5000
  
  validation {
    condition     = var.flask_port > 0 && var.flask_port <= 65535
    error_message = "Flask port must be between 1 and 65535."
  }
}

variable "enable_cutover_ui_access" {
  description = "Enable access to cutover management UI"
  type        = bool
  default     = true
}

variable "cutover_ui_port" {
  description = "Port for cutover management UI"
  type        = number
  default     = 8080
  
  validation {
    condition     = var.cutover_ui_port > 0 && var.cutover_ui_port <= 65535
    error_message = "Cutover UI port must be between 1 and 65535."
  }
}

variable "application_cidr_blocks" {
  description = "CIDR blocks allowed access to application endpoints"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  
  validation {
    condition = alltrue([
      for cidr in var.application_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All application CIDR blocks must be valid CIDR notation."
  }
}

variable "custom_application_ports" {
  description = "Custom application ports to open"
  type = list(object({
    port        = number
    description = string
    cidr_blocks = list(string)
  }))
  default = []
  
  validation {
    condition = alltrue([
      for port_config in var.custom_application_ports : 
      port_config.port > 0 && port_config.port <= 65535
    ])
    error_message = "All custom application ports must be between 1 and 65535."
  }
}

# =============================================================================
# ADDITIONAL SECURITY GROUP VARIABLES
# =============================================================================

variable "additional_redis_security_groups" {
  description = "Additional security group IDs that should have Redis access"
  type        = set(string)
  default     = []
  
  validation {
    condition = alltrue([
      for sg_id in var.additional_redis_security_groups : can(regex("^sg-", sg_id))
    ])
    error_message = "All additional security group IDs must start with 'sg-'."
  }
}

# =============================================================================
# TAGGING VARIABLES
# =============================================================================

variable "tags" {
  description = "Key-value tags to apply to all security groups"
  type        = map(string)
  default     = {}
}

# Legacy variables for backward compatibility
variable "owner" {
  description = "Owner tag (legacy - use tags variable instead)"
  type        = string
  default     = ""
}

variable "project" {
  description = "Project tag (legacy - use tags variable instead)"
  type        = string
  default     = ""
}