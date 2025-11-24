# =============================================================================
# DNS RECORDS FOR REDIS ENTERPRISE CLUSTER
# =============================================================================
# Creates Route53 DNS records as required by Redis Enterprise documentation:
# https://redis.io/docs/latest/operate/rs/networking/configuring-aws-route53-dns-redis-enterprise/
# =============================================================================

# Data source to get the hosted zone information
data "aws_route53_zone" "main" {
  zone_id = var.dns_hosted_zone_id
}

# Determine which IPs to use for DNS records
# Use public IPs if available, otherwise fall back to private IPs
locals {
  dns_ips = length(var.public_ips) > 0 ? var.public_ips : var.private_ips
}

# Individual node records removed - not required for Redis Enterprise operation
# SSH access is available via IPs from Terraform outputs

# NS Glue Records - Required by Redis Enterprise for cluster node discovery
# Creates: ns1.cluster-fqdn.domain.com, ns2.cluster-fqdn.domain.com, etc.
# Uses public IPs when available, private IPs for VPC-only deployments
resource "aws_route53_record" "redis_ns_glue" {
  count   = var.create_dns_records ? var.node_count : 0
  zone_id = var.dns_hosted_zone_id
  name    = "ns${count.index + 1}.${var.cluster_fqdn}.${data.aws_route53_zone.main.name}"
  type    = "A"
  ttl     = 300
  records = [local.dns_ips[count.index]]

  depends_on = [data.aws_route53_zone.main]
}

# Nameserver (NS) Record - Points to the glue records
# The Record Name must equal the FQDN of the Redis Enterprise cluster
resource "aws_route53_record" "redis_cluster_ns" {
  count           = var.create_dns_records ? 1 : 0
  zone_id         = var.dns_hosted_zone_id
  name            = "${var.cluster_fqdn}.${data.aws_route53_zone.main.name}"
  type            = "NS"
  ttl             = 300
  allow_overwrite = true
  records = [
    for i in range(var.node_count) :
    "ns${i + 1}.${var.cluster_fqdn}.${data.aws_route53_zone.main.name}"
  ]

  depends_on = [aws_route53_record.redis_ns_glue]
}

# UI access is handled through the NS delegation (cluster FQDN)
# Redis Enterprise manages internal routing to the UI

# Wildcard A Record for Redis database access - Points to primary node for database connections
# This enables access to Redis databases like redis-12000.redis-cluster.redisdemo.com
# Uses public IP when available, private IP for VPC-only deployments
resource "aws_route53_record" "redis_database_wildcard" {
  count   = var.create_dns_records ? 1 : 0
  zone_id = var.dns_hosted_zone_id
  name    = "*.${var.name_prefix}.${data.aws_route53_zone.main.name}"
  type    = "A"
  ttl     = 300
  records = [local.dns_ips[0]] # Primary node IP for database access

  depends_on = [data.aws_route53_zone.main]
}

# Wildcard A Record for private Redis database access - Points to primary node private IP for internal connections
# This enables private access to Redis databases like demo-12000-internal.redis-cluster.redisdemo.com from within VPC
# Always uses private IP regardless of public IP availability
resource "aws_route53_record" "redis_database_wildcard_internal" {
  count   = var.create_dns_records ? 1 : 0
  zone_id = var.dns_hosted_zone_id
  name    = "*-internal.${var.name_prefix}.${data.aws_route53_zone.main.name}"
  type    = "A"
  ttl     = 300
  records = [var.private_ips[0]] # Always use private IP for internal access

  depends_on = [data.aws_route53_zone.main]
}