output "hosted_zone_name" {
  description = "The name of the hosted zone"
  value       = var.create_dns_records ? data.aws_route53_zone.main.name : null
}

# Individual node record outputs removed - not required for Redis Enterprise operation

output "redis_node_glue_records" {
  description = "List of NS glue record FQDNs for Redis Enterprise cluster discovery"
  value = var.create_dns_records ? [
    for i in range(var.node_count) :
    aws_route53_record.redis_ns_glue[i].fqdn
  ] : []
}

output "redis_cluster_fqdn" {
  description = "FQDN for Redis Enterprise cluster (matches nameserver record)"
  value = var.create_dns_records ? "${var.cluster_fqdn}.${data.aws_route53_zone.main.name}" : null
}

output "redis_cluster_ui_fqdn" {
  description = "FQDN for Redis Enterprise UI access (name-prefix.domain.com)"
  value = var.create_dns_records ? "${var.name_prefix}.${data.aws_route53_zone.main.name}" : null
}

output "redis_cluster_ns_record" {
  description = "Nameserver record for Redis Enterprise cluster"
  value = var.create_dns_records ? aws_route53_record.redis_cluster_ns[0].fqdn : null
}

output "redis_ui_url" {
  description = "Full URL for Redis Enterprise UI (uses name-prefix as hostname)"
  value = var.create_dns_records ? "https://${var.name_prefix}.${data.aws_route53_zone.main.name}:8443" : null
}

output "redis_api_url" {
  description = "Full URL for Redis Enterprise API (uses cluster FQDN)"
  value = var.create_dns_records ? "https://${var.cluster_fqdn}.${data.aws_route53_zone.main.name}:9443" : null
}