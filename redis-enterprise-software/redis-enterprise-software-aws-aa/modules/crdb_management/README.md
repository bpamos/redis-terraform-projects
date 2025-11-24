# CRDB Management Module

Automates the creation of Redis Enterprise Active-Active (CRDB) databases across multiple participating clusters using the REST API.

## Purpose

Creates and manages conflict-free replicated databases (CRDBs) that provide active-active replication across geographically distributed Redis Enterprise clusters.

## Features

- **Automated CRDB Creation**: Uses REST API to create databases across all clusters
- **Multi-Region Support**: Works with 2+ participating clusters
- **Configuration Validation**: Validates CRDB settings before creation
- **Verification**: Optional verification that CRDB exists on all clusters
- **Causal Consistency**: Optional causal consistency for stronger guarantees

## Prerequisites

Before using this module:

1. ✅ Redis Enterprise clusters deployed in all regions
2. ✅ Clusters running identical Redis Enterprise versions
3. ✅ VPC peering established between all regions
4. ✅ Port 9443 accessible between all clusters
5. ✅ NTP/Chrony configured on all nodes
6. ✅ Cluster admin credentials available

## Usage

```hcl
module "crdb" {
  source = "./modules/crdb_management"

  crdb_name       = "active-active-db"
  crdb_port       = 12000
  crdb_memory_size = 1073741824  # 1GB

  enable_replication       = true
  enable_sharding          = false
  enable_causal_consistency = true

  participating_clusters = {
    "us-west-2" = {
      cluster_fqdn = "us-west-2.redis-aa.domain.com"
    }
    "us-east-1" = {
      cluster_fqdn = "us-east-1.redis-aa.domain.com"
    }
  }

  cluster_username = "admin@admin.com"
  cluster_password = "YourSecurePassword123"

  # Wait for VPC peering and clusters to be ready
  depends_on = [module.vpc_peering_mesh]
}
```

## Important Configuration Notes

### Cannot Change After Creation
- **Port**: Cannot be modified after CRDB creation
- **Sharding**: Cannot enable/disable after creation
- **Shards Count**: Cannot change if sharding is enabled

### Active-Active Requirements
- **Persistence**: Only AOF is supported (no snapshots)
- **Data Types**: Only CRDT data types for conflict resolution
- **Replication**: Recommended to enable for high availability

### Memory Sizing
- `crdb_memory_size` applies to ALL replicas across ALL shards
- Example: 1GB CRDB with 2 replicas = 2GB total per instance
- Plan accordingly for your data size and replication needs

## Connection Examples

After CRDB creation, connect from any region:

### Redis CLI
```bash
# Connect to us-west-2 instance
redis-cli -h redis-12000.us-west-2.redis-aa.domain.com -p 12000

# Connect to us-east-1 instance
redis-cli -h redis-12000.us-east-1.redis-aa.domain.com -p 12000

# Both instances have the same data with bi-directional sync
```

### Python (redis-py)
```python
import redis

# Connect to any region - all instances stay in sync
west_client = redis.StrictRedis(
    host='redis-12000.us-west-2.redis-aa.domain.com',
    port=12000,
    decode_responses=True
)

east_client = redis.StrictRedis(
    host='redis-12000.us-east-1.redis-aa.domain.com',
    port=12000,
    decode_responses=True
)

# Write to west, read from east
west_client.set('key', 'value')
# Data automatically replicates to east
print(east_client.get('key'))  # Returns 'value'
```

## Verification

The module includes built-in verification that checks CRDB existence on all participating clusters. Enable with:

```hcl
verify_crdb = true
```

## Manual Verification

Check CRDB status via REST API:

```bash
# Check CRDB on all clusters
for region in us-west-2 us-east-1; do
  echo "Checking $region..."
  curl -k -u "admin@admin.com:password" \
    https://$region.redis-aa.domain.com:9443/v1/crdbs | jq
done
```

## Troubleshooting

### CRDB Creation Fails

1. **Check cluster connectivity**:
   ```bash
   telnet us-east-1.redis-aa.domain.com 9443
   ```

2. **Verify cluster status**:
   ```bash
   curl -k -u "admin:pass" https://cluster-fqdn:9443/v1/cluster
   ```

3. **Check VPC peering**:
   ```bash
   # From us-west-2, ping us-east-1 private IP
   ping 10.1.4.10
   ```

4. **Verify NTP sync**:
   ```bash
   ssh node-ip "chronyc tracking"
   ```

### CRDB Shows as Degraded

- Check network connectivity between regions
- Verify security group rules allow required ports
- Check cluster logs for replication errors

## Resources Created

- CRDB database instances on all participating clusters
- Local configuration files (crdb_config_*.json)
- Verification outputs (crdb_creation_response.json)

## Deletion

**Important**: CRDB deletion is not automated to prevent accidental data loss.

To manually delete a CRDB:

```bash
# Delete from primary cluster
curl -k -u "admin:pass" \
  -X DELETE \
  https://primary-cluster:9443/v1/crdbs/CRDB-GUID
```

Or use the Cluster Manager UI.
