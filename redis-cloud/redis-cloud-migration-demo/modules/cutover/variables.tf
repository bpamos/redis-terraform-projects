variable "redis_cloud_endpoint" {
  description = "Redis Cloud endpoint to write to config file"
  type        = string
}

variable "redis_cloud_password" {
  description = "Redis Cloud password to write to config file"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key to connect to app EC2"
  type        = string
}

variable "ec2_application_ip" {
  description = "Public IP of the EC2 application node"
  type        = string
}



##### OLD CUTOVER

# variable "redis_active_endpoint" {
#   type        = string
#   description = "The active Redis endpoint to route application traffic to"
# }

# variable "cutover_strategy" {
#   type        = string
#   description = "Which cutover strategy to use: dns or config_file"
#   default     = "dns"
# }

# variable "route53_zone_id" {
#   type        = string
#   description = "The Route 53 Hosted Zone ID for DNS-based cutover"
#   default     = ""
# }

# variable "route53_subdomain" {
#   type        = string
#   description = "The subdomain prefix for the redis endpoint (e.g. 'demo' for redis.demo.example.com)"
#   default     = ""
# }

# variable "ssh_private_key_path" {
#   type        = string
#   description = "Path to the SSH private key file to connect to the EC2 instance"
# }

# variable "ec2_application_ip" {
#   type        = string
#   description = "The public IP address of the application EC2 instance"
# } 

# variable "base_domain" {
#   description = "Base DNS domain (e.g., redisdemo.com)"
#   type        = string
# }