# =============================================================================
# VARIABLES
# Only the bare minimum needed for deployment
# =============================================================================

variable "rediscloud_api_key" {
  description = "Redis Cloud API key"
  type        = string
  sensitive   = true
}

variable "rediscloud_secret_key" {
  description = "Redis Cloud secret key"
  type        = string
  sensitive   = true
}

variable "aws_account_id" {
  description = "AWS Account ID (12 digits)"
  type        = string
}

variable "credit_card_last_four" {
  description = "Last 4 digits of credit card for Redis Cloud billing"
  type        = string
}
