# =============================================================================
# SECURITY GROUPS FOR REDIS MIGRATION INFRASTRUCTURE
# =============================================================================

# Security group for RIOT EC2 instance
resource "aws_security_group" "riot_ec2" {
  name        = "${var.name_prefix}-riot-ec2-sg"
  description = "Security group for RIOT EC2 instance with Redis OSS and observability tools"
  vpc_id      = var.vpc_id

  # SSH access
  dynamic "ingress" {
    for_each = var.enable_ssh_access ? [1] : []
    content {
      description = "SSH access"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_cidr_blocks
    }
  }

  # Grafana UI (only if observability enabled)
  dynamic "ingress" {
    for_each = var.enable_observability_access ? [1] : []
    content {
      description = "Grafana dashboard access"
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = var.observability_cidr_blocks
    }
  }

  # Prometheus UI (only if observability enabled)
  dynamic "ingress" {
    for_each = var.enable_observability_access ? [1] : []
    content {
      description = "Prometheus dashboard access"
      from_port   = 9090
      to_port     = 9090
      protocol    = "tcp"
      cidr_blocks = var.observability_cidr_blocks
    }
  }

  # RIOT-X metrics endpoint
  dynamic "ingress" {
    for_each = var.enable_riotx_metrics ? [1] : []
    content {
      description = "RIOT-X Prometheus metrics exporter"
      from_port   = var.riotx_metrics_port
      to_port     = var.riotx_metrics_port
      protocol    = "tcp"
      cidr_blocks = var.metrics_cidr_blocks
    }
  }

  # Redis OSS access (for local testing)
  dynamic "ingress" {
    for_each = var.enable_redis_oss_access ? [1] : []
    content {
      description = "Redis OSS access for testing"
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      cidr_blocks = var.redis_oss_cidr_blocks
    }
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    var.owner != "" ? { Owner = var.owner } : {},
    var.project != "" ? { Project = var.project } : {},
    {
      Name = "${var.name_prefix}-riot-ec2-sg"
      Type = "RIOT-EC2-SecurityGroup"
    }
  )
}

# Security group for ElastiCache Redis
resource "aws_security_group" "elasticache" {
  name        = "${var.name_prefix}-elasticache-sg"
  description = "Security group for ElastiCache Redis cluster"
  vpc_id      = var.vpc_id

  # Redis access from RIOT EC2
  ingress {
    description     = "Redis access from RIOT EC2 instances"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.riot_ec2.id]
  }

  # Redis access from application EC2
  ingress {
    description     = "Redis access from application EC2 instances"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_application.id]
  }

  # Optional: Redis access from additional security groups
  dynamic "ingress" {
    for_each = var.additional_redis_security_groups
    content {
      description     = "Redis access from additional security group: ${ingress.value}"
      from_port       = 6379
      to_port         = 6379
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    var.owner != "" ? { Owner = var.owner } : {},
    var.project != "" ? { Project = var.project } : {},
    {
      Name = "${var.name_prefix}-elasticache-sg"
      Type = "ElastiCache-SecurityGroup"
    }
  )
}

# Security group for application EC2 instances
resource "aws_security_group" "ec2_application" {
  name        = "${var.name_prefix}-ec2-app-sg"
  description = "Security group for application EC2 instances (Flask app, cutover UI)"
  vpc_id      = var.vpc_id

  # SSH access
  dynamic "ingress" {
    for_each = var.enable_ssh_access ? [1] : []
    content {
      description = "SSH access"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_cidr_blocks
    }
  }

  # Flask application access
  dynamic "ingress" {
    for_each = var.enable_flask_access ? [1] : []
    content {
      description = "Flask application access"
      from_port   = var.flask_port
      to_port     = var.flask_port
      protocol    = "tcp"
      cidr_blocks = var.application_cidr_blocks
    }
  }

  # Cutover UI access
  dynamic "ingress" {
    for_each = var.enable_cutover_ui_access ? [1] : []
    content {
      description = "Cutover management UI access"
      from_port   = var.cutover_ui_port
      to_port     = var.cutover_ui_port
      protocol    = "tcp"
      cidr_blocks = var.application_cidr_blocks
    }
  }

  # Custom application ports
  dynamic "ingress" {
    for_each = var.custom_application_ports
    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    var.owner != "" ? { Owner = var.owner } : {},
    var.project != "" ? { Project = var.project } : {},
    {
      Name = "${var.name_prefix}-ec2-app-sg"
      Type = "Application-SecurityGroup"
    }
  )
}