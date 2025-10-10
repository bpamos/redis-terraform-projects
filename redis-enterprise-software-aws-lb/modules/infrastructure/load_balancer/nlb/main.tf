# =============================================================================
# AWS NETWORK LOAD BALANCER FOR REDIS ENTERPRISE
# =============================================================================
# Managed AWS NLB for Redis Enterprise cluster management and database access
# =============================================================================

# Network Load Balancer for Redis Enterprise
resource "aws_lb" "redis_enterprise" {
  name               = "${var.name_prefix}-redis-nlb"
  internal           = false
  load_balancer_type = "network"

  # Deploy across multiple AZs for high availability
  subnets = var.public_subnet_ids

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-redis-nlb"
    Type = "Redis-Enterprise-LoadBalancer"
  })
}

# =============================================================================
# TARGET GROUPS FOR REDIS ENTERPRISE SERVICES
# =============================================================================

# Target Group for Cluster UI (port 8443)
resource "aws_lb_target_group" "cluster_ui" {
  name     = "${var.name_prefix}-ui"
  port     = 8443
  protocol = "TCP"
  vpc_id   = var.vpc_id

  # Connection draining / deregistration delay
  # Default: 300 seconds (5 minutes) - allows existing connections to complete gracefully
  # PERFORMANCE TUNING: For faster failover, consider reducing to 30-60 seconds
  # Trade-off: Lower values = faster failover but may terminate active connections
  # deregistration_delay = 30  # Uncomment and adjust for faster failover

  # Enable session stickiness for Redis Enterprise UI (required per Redis documentation)
  stickiness {
    enabled = true
    type    = "source_ip"
  }

  # Health check configuration
  # Current settings: 30s interval × 2 unhealthy checks = ~60s detection time
  # Combined with 300s deregistration delay = ~6 minutes total failover time
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    port                = "8443"
    protocol            = "TCP"
    timeout             = 6
    unhealthy_threshold = 2
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ui-tg"
    Type = "Redis-Enterprise-UI-TargetGroup"
  })
}

# Target Group for REST API (port 9443)
resource "aws_lb_target_group" "rest_api" {
  name     = "${var.name_prefix}-api"
  port     = 9443
  protocol = "TCP"
  vpc_id   = var.vpc_id

  # Health check configuration
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    port                = "9443"
    protocol            = "TCP"
    timeout             = 6
    unhealthy_threshold = 2
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-api-tg"
    Type = "Redis-Enterprise-API-TargetGroup"
  })
}

# Target Group for Database traffic (port range 10000-19999)
# Note: NLB doesn't support port ranges, so we'll create for common database ports
resource "aws_lb_target_group" "database_ports" {
  count = 10 # Create target groups for ports 12000-12009 as examples

  name     = "${var.name_prefix}-db-${12000 + count.index}"
  port     = 12000 + count.index
  protocol = "TCP"
  vpc_id   = var.vpc_id

  # Health check configuration
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    port                = tostring(12000 + count.index)
    protocol            = "TCP"
    timeout             = 6
    unhealthy_threshold = 2
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-${12000 + count.index}-tg"
    Type = "Redis-Enterprise-Database-TargetGroup"
  })
}

# =============================================================================
# LOAD BALANCER LISTENERS
# =============================================================================

# Listener for Cluster UI (8443)
resource "aws_lb_listener" "cluster_ui" {
  load_balancer_arn = aws_lb.redis_enterprise.arn
  port              = "8443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cluster_ui.arn
  }
}

# Listener for REST API (9443)
resource "aws_lb_listener" "rest_api" {
  load_balancer_arn = aws_lb.redis_enterprise.arn
  port              = "9443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rest_api.arn
  }
}

# Listeners for Database ports
resource "aws_lb_listener" "database_ports" {
  count = length(aws_lb_target_group.database_ports)

  load_balancer_arn = aws_lb.redis_enterprise.arn
  port              = tostring(12000 + count.index)
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.database_ports[count.index].arn
  }
}

# =============================================================================
# TARGET GROUP ATTACHMENTS
# =============================================================================

# Attach Redis Enterprise instances to UI target group
resource "aws_lb_target_group_attachment" "cluster_ui" {
  count            = length(var.instance_ids)
  target_group_arn = aws_lb_target_group.cluster_ui.arn
  target_id        = var.instance_ids[count.index]
  port             = 8443
}

# Attach Redis Enterprise instances to API target group  
resource "aws_lb_target_group_attachment" "rest_api" {
  count            = length(var.instance_ids)
  target_group_arn = aws_lb_target_group.rest_api.arn
  target_id        = var.instance_ids[count.index]
  port             = 9443
}

# Attach Redis Enterprise instances to database target groups
resource "aws_lb_target_group_attachment" "database_ports" {
  count            = length(aws_lb_target_group.database_ports) * length(var.instance_ids)
  target_group_arn = aws_lb_target_group.database_ports[floor(count.index / length(var.instance_ids))].arn
  target_id        = var.instance_ids[count.index % length(var.instance_ids)]
  port             = 12000 + floor(count.index / length(var.instance_ids))
}