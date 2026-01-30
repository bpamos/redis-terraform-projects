# =============================================================================
# REDIS ENTERPRISE MONITORING MODULE - VARIABLES
# =============================================================================
# Prometheus + Grafana monitoring for Redis Enterprise Software deployments
# =============================================================================

# =============================================================================
# REQUIRED VARIABLES - BASTION CONNECTION
# =============================================================================

variable "bastion_public_ip" {
  description = "Public IP of the bastion host to install monitoring on"
  type        = string
}

variable "bastion_private_ip" {
  description = "Private IP of the bastion host (used for internal references)"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for connecting to bastion"
  type        = string
}

variable "ssh_user" {
  description = "SSH user for bastion host"
  type        = string
  default     = "ubuntu"
}

# =============================================================================
# REQUIRED VARIABLES - REDIS ENTERPRISE CLUSTER
# =============================================================================

variable "redis_cluster_fqdn" {
  description = "Fully qualified domain name of the Redis Enterprise cluster"
  type        = string
}

variable "redis_cluster_nodes" {
  description = "List of Redis Enterprise cluster node IPs (private IPs for scraping)"
  type        = list(string)
}

variable "redis_cluster_username" {
  description = "Redis Enterprise cluster admin username"
  type        = string
}

variable "redis_cluster_password" {
  description = "Redis Enterprise cluster admin password"
  type        = string
  sensitive   = true
}

# =============================================================================
# OPTIONAL VARIABLES - REDIS ENTERPRISE PORTS
# =============================================================================

variable "redis_metrics_port" {
  description = "Port for Redis Enterprise metrics endpoint (Prometheus scraping)"
  type        = number
  default     = 8070
}

variable "redis_api_port" {
  description = "Port for Redis Enterprise REST API"
  type        = number
  default     = 9443
}

# =============================================================================
# OPTIONAL VARIABLES - DATABASE CONFIGURATION
# =============================================================================

variable "redis_databases" {
  description = "Map of Redis databases for dashboard defaults. Example: { mydb = { port = 12000 } }"
  type = map(object({
    port = number
  }))
  default = {}
}

# =============================================================================
# OPTIONAL VARIABLES - PROMETHEUS CONFIGURATION
# =============================================================================

variable "prometheus_port" {
  description = "Port for Prometheus web UI"
  type        = number
  default     = 9090
}

variable "prometheus_retention_days" {
  description = "Number of days to retain Prometheus metrics data"
  type        = number
  default     = 15
}

variable "prometheus_scrape_interval" {
  description = "How often Prometheus scrapes metrics from Redis Enterprise"
  type        = string
  default     = "30s"
}

variable "metrics_endpoint_version" {
  description = "Redis Enterprise metrics endpoint version (v1 or v2)"
  type        = string
  default     = "v2"

  validation {
    condition     = contains(["v1", "v2"], var.metrics_endpoint_version)
    error_message = "Metrics endpoint version must be 'v1' or 'v2'."
  }
}

# =============================================================================
# OPTIONAL VARIABLES - GRAFANA CONFIGURATION
# =============================================================================

variable "grafana_port" {
  description = "Port for Grafana web UI"
  type        = number
  default     = 3000
}

variable "grafana_admin_user" {
  description = "Grafana admin username"
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Grafana admin password. If empty, a random password will be generated."
  type        = string
  default     = ""
  sensitive   = true
}

variable "grafana_anonymous_access" {
  description = "Enable anonymous access to Grafana dashboards (read-only)"
  type        = bool
  default     = true
}

variable "grafana_allowed_cidrs" {
  description = "CIDR blocks allowed to access Grafana UI"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# =============================================================================
# OPTIONAL VARIABLES - DASHBOARD CONFIGURATION
# =============================================================================

variable "install_ops_dashboards" {
  description = "Install Redis Enterprise ops dashboards (cluster, database, node, shard, latency, qps, active-active)"
  type        = bool
  default     = true
}

variable "dashboards_github_repo" {
  description = "GitHub repository for Redis Enterprise observability dashboards"
  type        = string
  default     = "redis-field-engineering/redis-enterprise-observability"
}

variable "dashboards_github_branch" {
  description = "Branch to download dashboards from"
  type        = string
  default     = "main"
}

# =============================================================================
# OPTIONAL VARIABLES - SECURITY GROUP
# =============================================================================

variable "bastion_security_group_id" {
  description = "Security group ID of the bastion host (to add Grafana/Prometheus ingress rules)"
  type        = string
}

variable "add_security_group_rules" {
  description = "Add ingress rules to the bastion security group for Grafana/Prometheus ports"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID (required if creating a new security group)"
  type        = string
  default     = ""
}

# =============================================================================
# OPTIONAL VARIABLES - TAGGING
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "redis"
}

variable "owner" {
  description = "Owner tag for resources"
  type        = string
  default     = ""
}

variable "project" {
  description = "Project tag for resources"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
