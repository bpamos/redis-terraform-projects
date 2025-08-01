output "cutover_ui_url" {
  description = "URL to access the cutover UI server"
  value       = "http://${var.ec2_application_ip}:8080"
}
