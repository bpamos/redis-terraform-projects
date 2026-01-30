# Redis Enterprise Monitoring Module

Deploys Prometheus and Grafana monitoring stack on a bastion host for Redis Enterprise Software clusters.

## Features

- **Prometheus** - Scrapes Redis Enterprise metrics via V2 endpoint (port 8070)
- **Grafana** - Pre-configured with Prometheus datasource and Redis Enterprise dashboards
- **Ops Dashboards** - Automatically downloads 7 operational dashboards from [redis-enterprise-observability](https://github.com/redis-field-engineering/redis-enterprise-observability)
- **No TLS** - HTTP-only access for simplicity (suitable for internal/VPC use)

## Dashboards Included

| Dashboard | Description |
|-----------|-------------|
| Cluster | Overall cluster health, quorum, memory, CPU |
| Database | Per-database metrics and performance |
| Node | Individual node metrics |
| Shard | Redis shard-level metrics |
| Latency | Request latency analysis (P95, P99) |
| QPS | Queries per second metrics |
| Active-Active | CRDB replication metrics |

## Prerequisites

- Bastion host running Ubuntu (created via `ec2_bastion` module)
- SSH access to bastion host
- Redis Enterprise cluster deployed and accessible from bastion

## Usage

```hcl
module "monitoring" {
  source = "../../modules/redis_enterprise_monitoring"

  # Bastion connection
  bastion_public_ip    = module.bastion[0].public_ip
  bastion_private_ip   = module.bastion[0].private_ip
  ssh_private_key_path = var.ssh_private_key_path
  ssh_user             = "ubuntu"

  # Redis Enterprise cluster details
  redis_cluster_fqdn     = module.cluster_bootstrap.cluster_fqdn
  redis_cluster_nodes    = module.redis_instances.private_ips
  redis_cluster_username = var.cluster_username
  redis_cluster_password = var.cluster_password

  # Security group for Grafana/Prometheus ports
  bastion_security_group_id = module.bastion[0].security_group_id
  grafana_allowed_cidrs     = var.allow_ssh_from

  # Tags
  name_prefix = local.name_prefix
  owner       = var.owner
  project     = var.project

  depends_on = [module.bastion, module.cluster_bootstrap]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bastion_public_ip | Public IP of the bastion host | `string` | n/a | yes |
| bastion_private_ip | Private IP of the bastion host | `string` | n/a | yes |
| ssh_private_key_path | Path to SSH private key | `string` | n/a | yes |
| redis_cluster_fqdn | Redis Enterprise cluster FQDN | `string` | n/a | yes |
| redis_cluster_nodes | List of Redis node private IPs | `list(string)` | n/a | yes |
| redis_cluster_username | Cluster admin username | `string` | n/a | yes |
| redis_cluster_password | Cluster admin password | `string` | n/a | yes |
| grafana_port | Grafana web UI port | `number` | `3000` | no |
| prometheus_port | Prometheus web UI port | `number` | `9090` | no |
| grafana_admin_password | Grafana admin password (auto-generated if empty) | `string` | `""` | no |
| grafana_anonymous_access | Enable anonymous dashboard viewing | `bool` | `true` | no |
| prometheus_retention_days | Metrics retention period | `number` | `15` | no |
| metrics_endpoint_version | V1 or V2 metrics endpoint | `string` | `"v2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| grafana_url | Public URL for Grafana |
| prometheus_url | Public URL for Prometheus |
| grafana_admin_password | Grafana admin password (sensitive) |
| redis_metrics_endpoint | Redis metrics endpoint being scraped |

## Accessing Dashboards

After deployment:

1. Open Grafana URL from outputs: `http://<bastion_ip>:3000`
2. If anonymous access is enabled, dashboards are immediately visible
3. Navigate to **Dashboards** → **Redis Enterprise Ops** folder
4. Select a dashboard (Cluster, Database, Node, etc.)

## Helper Scripts

Scripts are installed on the bastion host:

```bash
# Check monitoring stack status
./monitoring-status.sh

# View Prometheus scrape targets
./check-prometheus-targets.sh

# Reload Prometheus config
./reload-prometheus.sh
```

## Troubleshooting

### Prometheus not scraping metrics

```bash
# Check target status
./check-prometheus-targets.sh

# View Prometheus logs
journalctl -u prometheus -f

# Verify Redis metrics endpoint is accessible
curl -k https://<cluster_fqdn>:8070/v2
```

### Grafana dashboards not loading

```bash
# Check Grafana logs
journalctl -u grafana-server -f

# Verify dashboards are installed
ls -la /var/lib/grafana/dashboards/redis-enterprise/

# Check provisioning config
cat /etc/grafana/provisioning/dashboards/redis-enterprise.yml
```

## References

- [Redis Enterprise Prometheus Integration](https://redis.io/docs/latest/integrate/prometheus-with-redis-enterprise/)
- [Redis Enterprise Observability Repo](https://github.com/redis-field-engineering/redis-enterprise-observability)
