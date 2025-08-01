output "cutover_script_path" {
  value       = "/home/ubuntu/do_cutover.sh"
  description = "Path to the manual cutover script on the application EC2"
}


# OLD CUTOVER

# output "active_cutover_strategy" {
#   value       = var.cutover_strategy
#   description = "The currently selected cutover strategy"
# }

# output "active_redis_endpoint" {
#   value       = var.redis_active_endpoint
#   description = "The Redis endpoint currently targeted by the cutover logic"
# }

# output "cutover_dns_full_record" {
#   value       = var.cutover_strategy == "dns" ? "redis.${var.route53_subdomain}.${var.base_domain}" : ""
#   description = "Fully qualified DNS name when using DNS cutover"
# }
