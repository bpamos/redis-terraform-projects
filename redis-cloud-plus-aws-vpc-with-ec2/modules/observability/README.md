# Redis Cloud Observability Module

Automated Prometheus + Grafana monitoring for Redis Cloud databases with official operational dashboards.

## Quick Configuration

This module requires **minimal configuration** - just provide your Redis Cloud database endpoint:

```hcl
module "observability" {
  source = "./modules/observability"

  instance_id        = module.ec2_test.instance_id
  instance_public_ip = module.ec2_test.public_ip
  ssh_private_key    = file(var.ssh_private_key_path)
  redis_endpoint     = module.redis_database_primary.private_endpoint
}
```

## Key Configuration Changes (vs Default Prometheus)

This module makes **3 essential modifications** to work with Redis Cloud:

### 1. Prometheus Endpoint Format
**File**: `scripts/prometheus.yml.tpl`

```yaml
# Redis Cloud requires removing the database prefix from the endpoint
targets: ['internal.c48295.us-west-2-mz.ec2.cloud.rlrcp.com:8070']
# NOT: redis-18150.internal.c48295.us-west-2-mz.ec2.cloud.rlrcp.com:8070
```

**Why**: Redis Cloud Prometheus endpoint is at the subscription level, not database level.
**Reference**: https://redis.io/docs/latest/integrate/prometheus-with-redis-cloud/

### 2. Metrics API Version
**File**: `scripts/prometheus.yml.tpl`

```yaml
metrics_path: /v2
# NOT: /
```

**Why**: Redis Cloud uses v2 metrics API with enhanced metric names (e.g., `node_metrics_up`).
**Reference**: Redis Cloud Prometheus integration documentation

### 3. Grafana Datasource Name
**File**: `scripts/grafana-datasource.yml.tpl`

```yaml
datasources:
  - name: redis-cloud
    # NOT: Prometheus
```

**Why**: Official Redis Cloud dashboards expect datasource named `redis-cloud`.
**Reference**: https://redis.io/docs/latest/integrate/prometheus-with-redis-cloud/

## What Gets Deployed

### Infrastructure
- **Prometheus**: Scrapes Redis Cloud metrics every 30s via HTTPS
- **Grafana**: Pre-configured with `redis-cloud` datasource
- **Docker Compose**: Manages both services on EC2 instance

### Dashboards (7 Official Operational Dashboards)
All from [Redis Field Engineering Observability Repository](https://github.com/redis-field-engineering/redis-enterprise-observability):

1. **Active-Active** - Replication metrics for geo-distributed databases
2. **Cluster** - Cluster-level performance and health metrics
3. **Database** - Database operations and performance metrics
4. **Latency** - Request latency analysis (p50, p99, p99.9)
5. **Node** - Node-level resource utilization
6. **QPS** - Queries per second and throughput
7. **Shard** - Shard-level performance and distribution

**Source**: `grafana_v2/dashboards/grafana_v9-11/cloud/ops/`

## Access

After deployment (Terraform outputs):

```bash
# Grafana UI
http://<public-ip>:3000
Username: admin
Password: admin

# Prometheus UI
http://<public-ip>:9090
```

## Metrics Available

Example Redis Cloud metrics (v2 API):

```
node_metrics_up{cluster="...", instance="..."}
bdb_memory_limit{bdb="13660337", bdb_name="...", cluster="..."}
endpoint_client_connections{cluster="...", db="..."}
redis_server_used_memory{cluster="...", db="...", role="master"}
```

**Key Labels**:
- `cluster`: Redis Cloud subscription cluster FQDN
- `bdb`: Database ID
- `db`: Database identifier (same as bdb)
- `bdb_name`: Human-readable database name

## Documentation

- **Redis Cloud Prometheus Integration**: https://redis.io/docs/latest/integrate/prometheus-with-redis-cloud/
- **Official Dashboards Repository**: https://github.com/redis-field-engineering/redis-enterprise-observability
- **Grafana.com Dashboards**:
  - Subscription Status: https://grafana.com/grafana/dashboards/18406
  - Database Status: https://grafana.com/grafana/dashboards/18407

## Module Outputs

```hcl
output "grafana_url" {
  value = "http://<public-ip>:3000"
}

output "prometheus_url" {
  value = "http://<public-ip>:9090"
}

output "dashboard_urls" {
  value = {
    grafana_home = "http://<public-ip>:3000"
    note = "Access all imported Redis Cloud operational dashboards from the Grafana home page"
  }
}
```

## Notes

- **Security**: Default credentials (admin/admin) are for demo purposes only
- **Production**: Use secure passwords, enable HTTPS, restrict access with security groups
- **Retention**: Prometheus data is stored in Docker volume, persists across container restarts
- **Updates**: Dashboards are downloaded fresh on each deployment from official repository
