# =============================================================================
# PEERING CONNECTION OUTPUTS
# =============================================================================

output "peering_id" {
  description = "Redis Cloud subscription peering ID"
  value       = rediscloud_subscription_peering.peering.id
}

output "aws_peering_id" {
  description = "AWS VPC peering connection ID"
  value       = rediscloud_subscription_peering.peering.aws_peering_id
}

output "peering_status" {
  description = "Status of the Redis Cloud peering connection"
  value       = rediscloud_subscription_peering.peering.status
}

output "aws_peering_connection_id" {
  description = "AWS VPC peering connection ID (after acceptance)"
  value       = aws_vpc_peering_connection_accepter.accepter.id
}

# =============================================================================
# ROUTING OUTPUTS
# =============================================================================

output "primary_route_created" {
  description = "Whether the primary route was created"
  value       = var.create_route
}

output "additional_routes_count" {
  description = "Number of additional routes created"
  value       = length(var.additional_route_table_ids)
}

output "route_destination_cidr" {
  description = "CIDR block being routed to Redis Cloud"
  value       = var.peer_cidr_block
}

# =============================================================================
# CONFIGURATION SUMMARY
# =============================================================================

output "peering_config" {
  description = "Summary of peering configuration"
  value = {
    subscription_id    = var.subscription_id
    aws_account_id     = var.aws_account_id
    region            = var.region
    vpc_id            = var.vpc_id
    vpc_cidr          = var.vpc_cidr
    peer_cidr         = var.peer_cidr_block
    auto_accept       = var.auto_accept_peering
    activation_wait   = "${var.activation_wait_time}s"
  }
}