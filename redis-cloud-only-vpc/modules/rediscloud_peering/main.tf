# =============================================================================
# REDIS CLOUD VPC PEERING SETUP
# =============================================================================

# Wait for Redis Cloud subscription to be fully activated before creating peering
resource "null_resource" "wait_for_subscription_activation" {
  provisioner "local-exec" {
    command = "echo 'Waiting for Redis Cloud subscription activation...' && sleep ${var.activation_wait_time}"
  }

  triggers = {
    subscription_id = var.subscription_id
    wait_time      = var.activation_wait_time
  }
}

# Create VPC peering connection between Redis Cloud and AWS VPC
resource "rediscloud_subscription_peering" "peering" {
  subscription_id = var.subscription_id
  region          = var.region
  aws_account_id  = var.aws_account_id
  vpc_id          = var.vpc_id
  vpc_cidr        = var.vpc_cidr

  timeouts {
    create = var.peering_create_timeout
    delete = var.peering_delete_timeout
  }

  depends_on = [
    null_resource.wait_for_subscription_activation
  ]
}

# Accept the VPC peering connection on the AWS side
resource "aws_vpc_peering_connection_accepter" "accepter" {
  vpc_peering_connection_id = rediscloud_subscription_peering.peering.aws_peering_id
  auto_accept               = var.auto_accept_peering

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-redis-peering-accepter"
  })
}

# Add route to Redis Cloud network in the specified route table
resource "aws_route" "rediscloud_route" {
  count = var.create_route ? 1 : 0
  
  route_table_id            = var.route_table_id
  destination_cidr_block    = var.peer_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.accepter.id

  depends_on = [aws_vpc_peering_connection_accepter.accepter]
}

# Optional: Create routes for multiple route tables
resource "aws_route" "rediscloud_routes_multiple" {
  for_each = var.additional_route_table_ids
  
  route_table_id            = each.value
  destination_cidr_block    = var.peer_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.accepter.id

  depends_on = [aws_vpc_peering_connection_accepter.accepter]
}