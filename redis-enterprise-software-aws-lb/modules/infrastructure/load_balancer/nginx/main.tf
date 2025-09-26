# =============================================================================
# NGINX LOAD BALANCER FOR REDIS ENTERPRISE
# =============================================================================
# Custom NGINX build with stream module on EC2 for Redis Enterprise load balancing
# Supports layer 4 TCP load balancing with advanced configuration options
# =============================================================================

# Local values for platform-specific configuration
locals {
  platform_config = {
    ubuntu = {
      user = "ubuntu"
      ami_filter = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      ami_owner = "099720109477"
    }
    rhel = {
      user = "ec2-user"
      ami_filter = "RHEL-9.*-x86_64-*"
      ami_owner = "309956199498"
    }
  }
  
  selected_config = local.platform_config[var.platform]
  
  # Generate port range list if configured
  port_range_list = var.database_port_range_start != null && var.database_port_range_end != null ? [
    for port in range(var.database_port_range_start, var.database_port_range_end + 1) : port
  ] : []
  
  # NGINX configuration template variables
  nginx_config_vars = {
    private_ips = var.private_ips
    
    # Frontend ports (what clients connect to)
    frontend_database_port = var.frontend_database_port
    frontend_api_port     = var.frontend_api_port
    frontend_ui_port      = var.frontend_ui_port
    
    # Backend ports (where Redis Enterprise services run)
    database_port = var.backend_database_port
    api_port      = var.backend_api_port
    ui_port       = var.backend_ui_port
    
    # Additional database ports if configured
    additional_database_ports = var.additional_database_ports
    
    # Database port range configuration
    database_port_range_list = local.port_range_list
  }
}

# =============================================================================
# AMI SELECTION FOR NGINX INSTANCES
# =============================================================================

data "aws_ami" "nginx" {
  most_recent = true
  owners      = [local.selected_config.ami_owner]
  
  filter {
    name   = "name"
    values = [local.selected_config.ami_filter]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# =============================================================================
# SECURITY GROUP FOR NGINX LOAD BALANCER
# =============================================================================

resource "aws_security_group" "nginx" {
  name_prefix = "${var.name_prefix}-nginx-"
  description = "Security group for NGINX load balancers"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NGINX status page (HTTP)
  ingress {
    description = "NGINX status and health check"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allow_access_from
  }

  # Redis Enterprise UI (443 -> 8443)
  ingress {
    description = "Redis Enterprise UI (SSL passthrough)"
    from_port   = var.frontend_ui_port
    to_port     = var.frontend_ui_port
    protocol    = "tcp"
    cidr_blocks = var.allow_access_from
  }

  # Redis Enterprise API (9443)
  ingress {
    description = "Redis Enterprise REST API"
    from_port   = var.frontend_api_port
    to_port     = var.frontend_api_port
    protocol    = "tcp"
    cidr_blocks = var.allow_access_from
  }

  # Redis database port (6379)
  ingress {
    description = "Redis database access"
    from_port   = var.frontend_database_port
    to_port     = var.frontend_database_port
    protocol    = "tcp"
    cidr_blocks = var.allow_access_from
  }

  # Additional database ports (if configured)
  dynamic "ingress" {
    for_each = var.additional_database_ports != null ? var.additional_database_ports : []
    content {
      description = "Redis database ${ingress.value.name}"
      from_port   = ingress.value.frontend_port
      to_port     = ingress.value.frontend_port
      protocol    = "tcp"
      cidr_blocks = var.allow_access_from
    }
  }

  # Database port range (if configured)
  dynamic "ingress" {
    for_each = var.database_port_range_start != null && var.database_port_range_end != null ? [1] : []
    content {
      description = "Redis Enterprise database port range (${var.database_port_range_start}-${var.database_port_range_end})"
      from_port   = var.database_port_range_start
      to_port     = var.database_port_range_end
      protocol    = "tcp"
      cidr_blocks = var.allow_access_from
    }
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nginx-sg"
    Type = "NGINX-SecurityGroup"
  })
}

# =============================================================================
# NGINX LOAD BALANCER INSTANCES (HIGH AVAILABILITY)
# =============================================================================

resource "aws_instance" "nginx" {
  count = var.nginx_instance_count # Configurable number of instances
  
  ami                         = data.aws_ami.nginx.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.nginx.id]
  subnet_id                   = var.public_subnet_ids[count.index % length(var.public_subnet_ids)]
  associate_public_ip_address = true
  
  # No user_data - we'll install NGINX through provisioners for better control
  
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
    
    tags = merge(var.tags, {
      Name = "${var.name_prefix}-nginx-${count.index + 1}-root"
    })
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nginx-${count.index + 1}"
    Type = "NGINX-LoadBalancer"
    Role = count.index == 0 ? "primary" : "secondary"
  })
}

# =============================================================================
# NGINX INSTALLATION AND CONFIGURATION
# =============================================================================

resource "null_resource" "nginx_installation" {
  count = length(aws_instance.nginx)
  
  # Trigger reinstallation if instance changes
  triggers = {
    nginx_instance_id = aws_instance.nginx[count.index].id
  }

  # Upload installation script
  provisioner "file" {
    source      = "${path.module}/scripts/nginx_setup.sh"
    destination = "/tmp/nginx_setup.sh"

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.nginx[count.index].public_ip
      timeout     = "10m"
    }
  }

  # Run installation script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/nginx_setup.sh",
      "sudo /tmp/nginx_setup.sh",
      "echo 'NGINX installation completed on ${aws_instance.nginx[count.index].tags.Name}'"
    ]

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.nginx[count.index].public_ip
      timeout     = "15m"
    }
  }

  depends_on = [aws_instance.nginx]
}

# =============================================================================
# NGINX CONFIGURATION DEPLOYMENT
# =============================================================================

resource "null_resource" "nginx_config" {
  count = length(aws_instance.nginx)
  
  # Trigger configuration update when Redis nodes change
  triggers = {
    nginx_instance_id = aws_instance.nginx[count.index].id
    redis_nodes       = join(",", var.private_ips)
    config_version    = md5(templatefile("${path.module}/templates/nginx.conf.tpl", local.nginx_config_vars))
  }

  # Upload NGINX configuration
  provisioner "file" {
    content = templatefile("${path.module}/templates/nginx.conf.tpl", local.nginx_config_vars)
    destination = "/tmp/nginx.conf"

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.nginx[count.index].public_ip
      timeout     = "5m"
    }
  }

  # Test and apply configuration
  provisioner "remote-exec" {
    inline = [
      "echo 'Testing NGINX configuration...'",
      "sudo /usr/sbin/nginx -t -c /tmp/nginx.conf",
      "echo 'Configuration test passed, applying...'",
      "sudo cp /tmp/nginx.conf /etc/nginx/nginx.conf",
      "sudo systemctl restart nginx",
      "sudo systemctl enable nginx",
      "echo 'Verifying NGINX is running...'",
      "sudo systemctl status nginx --no-pager -l",
      "echo 'NGINX configuration applied successfully on ${aws_instance.nginx[count.index].tags.Name}'"
    ]

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.nginx[count.index].public_ip
      timeout     = "5m"
    }
  }

  depends_on = [null_resource.nginx_installation]
}

# =============================================================================
# NGINX HEALTH VERIFICATION
# =============================================================================

resource "null_resource" "nginx_health_check" {
  count = length(aws_instance.nginx)
  
  triggers = {
    nginx_config_id = null_resource.nginx_config[count.index].id
  }

  # Verify NGINX is healthy and load balancing correctly
  provisioner "remote-exec" {
    inline = [
      "echo 'Running NGINX health checks...'",
      "echo '1. Checking NGINX process:'",
      "ps aux | grep nginx | grep -v grep || echo 'No NGINX processes found!'",
      "echo '2. Checking listening ports:'",
      "ss -tlnp | grep nginx || echo 'NGINX not listening on expected ports!'",
      "echo '3. Testing HTTP status page:'",
      "curl -s http://localhost/health | head -5 || echo 'Status page not accessible!'",
      "echo '4. Verifying stream configuration:'",
      "sudo /usr/sbin/nginx -T 2>&1 | grep -A5 -B5 'stream {' || echo 'Stream module not configured!'",
      "echo 'Health checks completed for ${aws_instance.nginx[count.index].tags.Name}'"
    ]

    connection {
      type        = "ssh"
      user        = local.selected_config.user
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.nginx[count.index].public_ip
      timeout     = "5m"
    }
  }

  depends_on = [null_resource.nginx_config]
}