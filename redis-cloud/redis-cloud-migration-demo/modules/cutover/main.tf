locals {
  redis_host = split(":", var.redis_cloud_endpoint)[0]
  redis_port = split(":", var.redis_cloud_endpoint)[1]
}

# Create simple cutover script that avoids permission issues
resource "null_resource" "prepare_cutover_script" {
  
  # Upload the simple cutover script
  provisioner "file" {
    source      = "${path.module}/scripts/simple_cutover.sh"
    destination = "/home/ubuntu/do_cutover.sh"
    
    connection {
      type        = "ssh"
      host        = var.ec2_application_ip
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      timeout     = "10m"
    }
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = var.ec2_application_ip
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      timeout     = "10m"
    }

    inline = [
      "echo '🚀 Setting up simple cutover script...'",
      
      # Set environment variables in the script
      "sed -i 's/$${REDIS_CLOUD_ENDPOINT:-.*}/${local.redis_host}/g' /home/ubuntu/do_cutover.sh",
      "sed -i 's/$${REDIS_CLOUD_PORT:-.*}/${local.redis_port}/g' /home/ubuntu/do_cutover.sh", 
      "sed -i 's/$${REDIS_CLOUD_PASSWORD:-.*}/${var.redis_cloud_password}/g' /home/ubuntu/do_cutover.sh",
      
      # Make executable
      "chmod +x /home/ubuntu/do_cutover.sh",
      
      "echo '✅ Simple cutover script ready!'",
      "echo 'Usage: /home/ubuntu/do_cutover.sh {validate|cutover|rollback|status}'"
    ]
  }
}






#### OLD CUTOVER

# resource "null_resource" "redis_config_file" {
#   count = var.cutover_strategy == "config_file" ? 1 : 0

#   provisioner "remote-exec" {
#     connection {
#       type        = "ssh"
#       host        = var.ec2_application_ip
#       user        = "ubuntu"
#       private_key = file(var.ssh_private_key_path)
#     }

#     inline = [
#       "echo '${var.redis_active_endpoint}' > /home/ubuntu/redis_target.txt"
#     ]
#   }
# }

# locals {
#   redis_endpoint_no_port = split(":", var.redis_active_endpoint)[0]
# }

# resource "aws_route53_record" "redis_cname" {
#   count   = var.cutover_strategy == "dns" ? 1 : 0

#   zone_id = var.route53_zone_id
#   name    = "redis.${var.route53_subdomain}.${var.base_domain}"
#   type    = "CNAME"
#   ttl     = 60
#   records = [local.redis_endpoint_no_port]
# }
