# =============================================================================
# REDIS CLOUD SUBSCRIPTION OUTPUTS
# =============================================================================

output "subscription_id" {
  description = "Redis Cloud subscription ID"
  value       = rediscloud_subscription.redis.id
}

output "subscription_name" {
  description = "Redis Cloud subscription name"
  value       = rediscloud_subscription.redis.name
}

output "subscription_region" {
  description = "Redis Cloud subscription region"
  value       = var.rediscloud_region
}

output "subscription_cidr" {
  description = "CIDR block of the subscription VPC"
  value       = var.networking_deployment_cidr
}

output "subscription_payment_method_id" {
  description = "Payment method ID used for subscription"
  value       = rediscloud_subscription.redis.payment_method_id
}