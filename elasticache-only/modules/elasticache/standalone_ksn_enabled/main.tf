resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name_prefix}-${var.replication_group_suffix}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name    = "${var.name_prefix}-${var.replication_group_suffix}-subnet-group"
    Owner   = var.owner
    Project = var.project
  }
}

resource "aws_elasticache_parameter_group" "this" {
  name   = "${var.name_prefix}-${var.replication_group_suffix}-parameter-group"
  family = "redis7"

  parameter {
    name  = "notify-keyspace-events"
    value = "AKE"
  }

  tags = {
    Name    = "${var.name_prefix}-${var.replication_group_suffix}-parameter-group"
    Owner   = var.owner
    Project = var.project
  }
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id       = "${var.name_prefix}-${var.replication_group_suffix}"
  description                = "Standalone ElastiCache Redis with keyspace notifications"
  engine                     = "redis"
  engine_version             = "7.0"
  node_type                  = var.node_type
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  parameter_group_name       = aws_elasticache_parameter_group.this.name
  security_group_ids         = [var.security_group_id]
  replicas_per_node_group    = var.replicas
  automatic_failover_enabled = var.replicas > 0 ? true : false
  multi_az_enabled           = var.replicas > 0 ? true : false
  apply_immediately          = true
  port                       = 6379

  tags = {
    Name    = "${var.name_prefix}-${var.replication_group_suffix}"
    Owner   = var.owner
    Project = var.project
  }
}
