# Redis Database Creation

This Terraform configuration now automatically creates a sample Redis database after the cluster is fully deployed.

## Configuration

The database creation is controlled by these variables in `terraform.tfvars`:

```hcl
# Automatic Database Creation
create_sample_database = true               # Create a sample Redis database automatically
sample_db_name        = "demo"              # Name for the sample database
sample_db_port        = 12000               # Port for the sample database (10000-19999)
sample_db_memory      = 100                 # Memory size in MB for the sample database
```

## What Gets Created

When `create_sample_database = true`, the deployment will:

1. **Create Database**: Uses `rladmin create db` command to create a Redis database
2. **Configure Replication**: Enables replication for high availability
3. **Set Memory Limit**: Configures the specified memory size
4. **Assign Port**: Uses the specified port (default: 12000)

## Database Endpoints

After deployment, the database will have both private and public endpoints:

### External Endpoint (Internet Access)
```
<sample_db_name>-<sample_db_port>.<cluster_fqdn>:<sample_db_port>
```
Example: `demo-12000.redis-cluster.redisdemo.com:12000`

### Internal Endpoint (VPC Access Only)
```
<sample_db_name>-<sample_db_port>-internal.<cluster_fqdn>:<sample_db_port>
```
Example: `demo-12000-internal.redis-cluster.redisdemo.com:12000`

## Terraform Outputs

The deployment provides these database-related outputs:

- `sample_database_info`: Complete database information
- `sample_database_endpoint`: External FQDN endpoint for connections
- `redis_connection_examples`: Example redis-cli commands

## Connection Examples

### External Access (From Internet)
```bash
# Connect using external FQDN
redis-cli -h demo-12000.redis-cluster.redisdemo.com -p 12000

# Test external connection
redis-cli -h demo-12000.redis-cluster.redisdemo.com -p 12000 ping
```

### Private Access (From Within VPC)
```bash
# Connect using internal FQDN (from EC2 instances in same VPC)
redis-cli -h demo-12000-internal.redis-cluster.redisdemo.com -p 12000

# Test private connection
redis-cli -h demo-12000-internal.redis-cluster.redisdemo.com -p 12000 ping
```

### Direct IP Access (Fallback)
```bash
# Connect using direct public IP
redis-cli -h <PRIMARY_NODE_PUBLIC_IP> -p 12000

# Connect using direct private IP (from within VPC)
redis-cli -h <PRIMARY_NODE_PRIVATE_IP> -p 12000
```

## Customization

To customize the database:

1. Edit values in `terraform.tfvars`
2. Run `terraform apply`
3. The database will be recreated with new settings

To disable automatic database creation, set `create_sample_database = false`.

## Implementation Details

- Database creation happens after all cluster nodes are joined
- Uses Redis Enterprise's `rladmin` CLI tool
- Includes error handling and verification
- Waits for cluster to be fully ready before creating database
- Creates database on the primary node (node 1)