resource "null_resource" "deploy_cutover_ui" {
  depends_on = []

  # Create upload directories first
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /tmp/cutover_ui",
      "mkdir -p /tmp/cutover_ui/templates"
    ]
    
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = var.ec2_application_ip
      timeout     = "5m"
    }
  }

  # Upload enhanced UI server script (prettier redesigned version with RIOT controls and working rollback)
  provisioner "file" {
    source      = "${path.module}/scripts/enhanced_ui_server_redesigned.py"
    destination = "/tmp/cutover_ui/enhanced_ui_server_redesigned.py"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = var.ec2_application_ip
      timeout     = "10m"
    }
  }


  # Upload main cutover script with rollback functionality
  provisioner "file" {
    source      = "${path.module}/scripts/do_cutover.sh"
    destination = "/tmp/cutover_ui/do_cutover.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = var.ec2_application_ip
      timeout     = "10m"
    }
  }

  # Upload requirements file
  provisioner "file" {
    source      = "${path.module}/scripts/requirements.txt"
    destination = "/tmp/cutover_ui/requirements.txt"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = var.ec2_application_ip
      timeout     = "10m"
    }
  }

  # Upload HTML template directory
  provisioner "file" {
    source      = "${path.module}/scripts/templates/"
    destination = "/tmp/cutover_ui/templates/"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = var.ec2_application_ip
      timeout     = "10m"
    }
  }


  # Upload SSH key for RIOT control
  provisioner "file" {
    source      = var.ssh_private_key_path
    destination = "/tmp/cutover_ui/bamos-aws-us-west-2.pem"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = var.ec2_application_ip
      timeout     = "10m"
    }
  }

  # Deploy enhanced cutover UI with improved security
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = var.ec2_application_ip
      timeout     = "15m"
    }

    inline = [
      "echo '🚀 Deploying Enhanced Cutover UI...'",
      # Create secure configuration directory
      "sudo mkdir -p /opt/cutover-ui",
      "sudo chown ubuntu:ubuntu /opt/cutover-ui",
      # Create secure configuration file
      "cat > /opt/cutover-ui/.env << 'CONFIG'",
      "# Enhanced Cutover UI Configuration",
      "REDIS_CLOUD_ENDPOINT=${var.redis_cloud_endpoint}",
      "REDIS_CLOUD_PORT=${var.redis_cloud_port}",
      "REDIS_CLOUD_PASSWORD=${var.redis_cloud_password}",
      "EC2_PUBLIC_IP=${var.ec2_application_ip}",
      "RIOT_PUBLIC_IP=${var.riot_public_ip}",
      "SECRET_KEY=your-secret-key-change-in-production",
      "FLASK_ENV=production",
      "# Redis/ElastiCache endpoints for scripts",
      "REDIS_CLOUD_HOST=${var.redis_cloud_endpoint}",
      "ELASTICACHE_HOST=${var.elasticache_endpoint}",
      "ELASTICACHE_PORT=${var.elasticache_port}",
      "ELASTICACHE_PASSWORD=${var.elasticache_password}",
      "CONFIG",
      # Secure the configuration file
      "chmod 600 /opt/cutover-ui/.env",
      # Secure the SSH key for RIOT control
      "chmod 600 /tmp/cutover_ui/bamos-aws-us-west-2.pem",
      "cp /tmp/cutover_ui/bamos-aws-us-west-2.pem /home/ubuntu/",
      "chmod 600 /home/ubuntu/bamos-aws-us-west-2.pem",
      # Install Python dependencies and setup cutover UI
      "python3 -m pip install --user -r /tmp/cutover_ui/requirements.txt",
      "sudo mkdir -p /opt/cutover-ui/templates",
      "sudo cp /tmp/cutover_ui/enhanced_ui_server_redesigned.py /opt/cutover-ui/",
      "sudo cp /tmp/cutover_ui/templates/index.html /opt/cutover-ui/templates/",
      "sudo chown -R ubuntu:ubuntu /opt/cutover-ui",
      # Make cutover script executable
      "cp /tmp/cutover_ui/do_cutover.sh /home/ubuntu/",
      "chmod +x /home/ubuntu/do_cutover.sh",
      # Create systemd service for cutover UI
      "cat > /tmp/cutover-ui.service << 'EOF'",
      "[Unit]",
      "Description=Redis Migration Cutover UI",
      "After=network.target",
      " ",
      "[Service]",
      "Type=simple",
      "User=ubuntu",
      "WorkingDirectory=/opt/cutover-ui",
      "ExecStart=/usr/bin/python3 enhanced_ui_server_redesigned.py",
      "Restart=always",
      "RestartSec=3",
      " ",
      "[Install]",
      "WantedBy=multi-user.target",
      "EOF",
      "sudo mv /tmp/cutover-ui.service /etc/systemd/system/cutover-ui.service",
      # Enable and start the service
      "sudo systemctl daemon-reload",
      "sudo systemctl enable cutover-ui",
      "sudo systemctl start cutover-ui",
      # Display access information
      "echo ''",
      "echo '✅ Redis Migration Demo UI deployed successfully!'",
      "echo '🌐 Main UI: http://${var.ec2_application_ip}:8080'",
      "echo '🎮 8-button interface with restart functionality!'",
      "echo '🎮 No authentication required - ready for demo!'",
      "echo ''"
    ]
  }
}
