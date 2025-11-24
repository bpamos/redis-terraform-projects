# =============================================================================
# SINGLE REGION MODULE VARIABLES
# =============================================================================

variable "region" {
  description = "AWS region for this cluster"
  type        = string
}

variable "region_config" {
  description = "Region-specific configuration"
  type = object({
    vpc_cidr             = string
    key_name             = string
    ssh_key_path         = string
    availability_zones   = list(string)
    public_subnet_cidrs  = list(string)
    private_subnet_cidrs = list(string)
  })
}

variable "user_prefix" {
  description = "User prefix for resource naming"
  type        = string
}

variable "cluster_name" {
  description = "Cluster name"
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

variable "dns_hosted_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}

variable "hosted_zone_name" {
  description = "Route53 hosted zone name"
  type        = string
}

variable "create_dns_records" {
  description = "Create DNS records"
  type        = bool
}

variable "platform" {
  description = "Operating system platform (ubuntu or rhel)"
  type        = string
}

variable "node_count" {
  description = "Number of Redis Enterprise nodes in the cluster"
  type        = number
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "re_download_url" {
  description = "Redis Enterprise download URL"
  type        = string
}

variable "cluster_username" {
  description = "Cluster admin username"
  type        = string
}

variable "cluster_password" {
  description = "Cluster admin password"
  type        = string
  sensitive   = true
}

variable "rack_awareness" {
  description = "Enable rack awareness"
  type        = bool
}

variable "flash_enabled" {
  description = "Enable Redis on Flash"
  type        = bool
}

variable "create_sample_database" {
  description = "Create sample database"
  type        = bool
}

variable "sample_db_name" {
  description = "Sample database name"
  type        = string
}

variable "sample_db_port" {
  description = "Sample database port"
  type        = number
}

variable "sample_db_memory" {
  description = "Sample database memory in MB"
  type        = number
}

variable "node_root_size" {
  description = "Root volume size in GB"
  type        = number
}

variable "data_volume_size" {
  description = "Data volume size in GB"
  type        = number
}

variable "data_volume_type" {
  description = "Data volume type"
  type        = string
}

variable "persistent_volume_size" {
  description = "Persistent volume size in GB"
  type        = number
}

variable "persistent_volume_type" {
  description = "Persistent volume type"
  type        = string
}

variable "ebs_encryption_enabled" {
  description = "Enable EBS encryption"
  type        = bool
}

variable "associate_public_ip_address" {
  description = "Associate public IP addresses with instances"
  type        = bool
}

variable "use_elastic_ips" {
  description = "Use Elastic IPs for instances"
  type        = bool
}

variable "peer_region_cidrs" {
  description = "List of VPC CIDRs from other regions"
  type        = list(string)
}

variable "allow_ssh_from" {
  description = "List of CIDRs allowed to SSH"
  type        = list(string)
}

# =============================================================================
# TEST NODE CONFIGURATION
# =============================================================================

variable "enable_test_node" {
  description = "Create a test node in this region for Redis testing"
  type        = bool
  default     = true
}

variable "test_node_instance_type" {
  description = "Instance type for test node"
  type        = string
  default     = "t3.small"
}
