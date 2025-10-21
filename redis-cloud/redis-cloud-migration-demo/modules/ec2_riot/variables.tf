variable "name_prefix" {
  type = string
}

variable "ami_id" {
  description = "AMI ID to use for EC2"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for RIOT + Redis OSS"
  type        = string
  default     = "t2.xlarge"
}

variable "subnet_id" {
  description = "The ID of the subnet to launch the EC2 instance into"
  type        = string
}

variable "security_group_id" {
  description = "Security group for EC2"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "owner" {
  type = string
}

variable "project" {
  type = string
}


variable "ssh_private_key_path" {
  description = "Path to private key file for SSH access"
  type        = string
}

# Optional configuration variables
variable "riotx_version" {
  description = "Version of RIOT-X to install"
  type        = string
  default     = "0.7.3"
}

variable "docker_compose_version" {
  description = "Version of Docker Compose to install"
  type        = string
  default     = "v2.27.1"
}

variable "enable_observability" {
  description = "Whether to install Prometheus and Grafana"
  type        = bool
  default     = true
}
