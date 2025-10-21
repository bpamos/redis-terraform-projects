# Redis Database Management Module

This module handles the automated creation and management of Redis databases within the Redis Enterprise cluster, providing both private and public endpoint access for applications.

## Overview

After the Redis Enterprise cluster is fully operational, this module creates sample databases that demonstrate the dual endpoint architecture, allowing applications to connect via either private (VPC-internal) or public (internet-accessible) endpoints.

## What This Module Does

### 1. **Sample Database Creation**
- Creates a Redis database using the Redis Enterprise REST API
- Configures database with specified memory, port, and replication settings
- Automatically inherits private/public endpoint configuration from cluster setup
- Supports both single-node and multi-node cluster deployments

### 2. **Database Status Verification**
- Monitors database activation status after creation
- Waits for database to become fully operational
- Verifies database health using `rladmin status databases`

### 3. **Endpoint Configuration**
- Generates both private and public endpoint FQDNs
- Provides connection information for applications
- Supports DNS-based endpoint resolution

## Redis Database Creation Process

### Step 1: REST API Database Creation
```bash
curl -k -L -u '<username>:<password>' \
  -H 'Content-type:application/json' \
  -d '{
    "name": "<database-name>",
    "type": "redis", 
    "memory_size": <memory-in-bytes>,
    "port": <port-number>,
    "replication": false
  }' \
  https://localhost:9443/v1/bdbs
```

**Key Parameters:**
- `name`: Database name (e.g., "demo")
- `type`: Database type ("redis" for standard Redis)
- `memory_size`: Memory allocation in bytes (100MB = 104857600 bytes)
- `port`: Database port (10000-19999 range)
- `replication`: Set to false for single-node deployments

### Step 2: Database Status Verification
```bash
sudo /opt/redislabs/bin/rladmin status databases
```

This command verifies:
- Database state is "active"
- Proper port assignment
- Memory allocation
- Endpoint accessibility

## Database Endpoint Architecture

When a database is created in a properly configured Redis Enterprise cluster with `register_dns_suffix`, it automatically receives both endpoint types:

### Public Endpoint (External Access)
```
Format: <database-name>-<port>.<cluster-fqdn>:<port>
Example: demo-12000.redis-cluster.example.com:12000
```
- **Access**: Internet-accessible
- **DNS**: Resolves to cluster nodes' public IP addresses
- **Use Case**: Applications running outside AWS VPC
- **Security**: Configure security groups to control access

### Private Endpoint (VPC Internal Access)  
```
Format: <database-name>-<port>-internal.<cluster-fqdn>:<port>
Example: demo-12000-internal.redis-cluster.example.com:12000
```
- **Access**: VPC-internal only
- **DNS**: Resolves to cluster nodes' private IP addresses
- **Use Case**: Applications running within the same AWS VPC
- **Performance**: Lower latency, no internet gateway traversal

## Database Configuration Options

### Memory Configuration
```hcl
sample_db_memory = 100  # Memory in MB
```
- Minimum: 100MB
- Maximum: 10000MB (configurable)
- Actual allocation: Value × 1,048,576 (converts MB to bytes)

### Port Configuration
```hcl
sample_db_port = 12000  # Database port
```
- Valid range: 10000-19999
- Must not conflict with other databases
- Standard Redis port (6379) not recommended for production

### Replication Settings
```hcl
# For single-node clusters
"replication": false

# For multi-node clusters (3+ nodes)
"replication": true
```

## Connection Examples

### Applications Connecting to Public Endpoint
```bash
# Redis CLI connection (external)
redis-cli -h demo-12000.redis-cluster.example.com -p 12000

# Application connection string (external)
redis://demo-12000.redis-cluster.example.com:12000

# Test connectivity
redis-cli -h demo-12000.redis-cluster.example.com -p 12000 ping
```

### Applications Connecting to Private Endpoint
```bash
# Redis CLI connection (internal/VPC)
redis-cli -h demo-12000-internal.redis-cluster.example.com -p 12000

# Application connection string (internal/VPC)
redis://demo-12000-internal.redis-cluster.example.com:12000

# Test connectivity from VPC
redis-cli -h demo-12000-internal.redis-cluster.example.com -p 12000 ping
```

## Prerequisites for Private/Public Endpoints

This module works correctly only when the cluster was created with proper private endpoint support:

1. **Cluster Creation**: Must include `register_dns_suffix` flag
2. **External Addresses**: All nodes must have external addresses configured
3. **DNS Configuration**: Wildcard DNS records must be properly set up
   - `*.cluster-fqdn` → Public IPs (external endpoints)
   - `*-internal.cluster-fqdn` → Private IPs (internal endpoints)

## Implementation Details

### Platform Support
- **Ubuntu 22.04**: Uses `ubuntu` SSH user
- **RHEL 9**: Uses `ec2-user` SSH user
- Automatic platform detection and configuration

### API Authentication
- Uses cluster admin credentials for REST API calls
- Supports email-format usernames (admin@admin.com)
- Secure credential handling during database operations

### Error Handling
- Database creation validation via HTTP response
- Status verification with timeout protection
- Comprehensive error messaging for troubleshooting

## Database Management Best Practices

### Security
- **Network Segmentation**: Use private endpoints for VPC-internal applications
- **Access Control**: Configure security groups to restrict public endpoint access
- **Authentication**: Enable Redis AUTH for production databases

### Performance
- **Endpoint Selection**: Use private endpoints for better performance within VPC
- **Memory Sizing**: Size databases based on expected data volume
- **Port Management**: Use consistent port ranges for easier management

### Monitoring
- **Health Checks**: Regularly verify database status via `rladmin status`
- **Connection Testing**: Test both endpoint types after deployment
- **Resource Usage**: Monitor memory and connection utilization

## Terraform Configuration

### Required Variables
```hcl
create_sample_database = true     # Enable/disable database creation
sample_db_name        = "demo"    # Database name
sample_db_port        = 12000     # Database port  
sample_db_memory      = 100       # Memory allocation in MB
```

### Optional Customization
```hcl
# Disable sample database creation
create_sample_database = false

# Custom database configuration
sample_db_name   = "myapp-cache"
sample_db_port   = 15000
sample_db_memory = 512
```

## Outputs

The module provides comprehensive database information:

```hcl
# Complete database information
sample_database_info = {
  name              = "demo"
  port              = 12000
  memory            = 100
  endpoint          = "redis-12000.cluster.example.com"
  endpoint_private  = "redis-12000-internal.cluster.example.com"
  created           = true
}

# Individual endpoint outputs
sample_database_endpoint         = "redis-12000.cluster.example.com"
sample_database_endpoint_private = "redis-12000-internal.cluster.example.com"
```

## Redis Enterprise Documentation References

This implementation follows Redis Enterprise best practices:

- **Database Management**: [Creating and Managing Databases](https://redis.io/docs/latest/operate/rs/databases/)
- **REST API Reference**: [REST API - Database Operations](https://redis.io/docs/latest/operate/rs/references/rest-api/requests/bdbs/)
- **Private/Public Endpoints**: [Private and Public Endpoints](https://redis.io/docs/latest/operate/rs/networking/private-public-endpoints/)
- **Database Configuration**: [Database Configuration Options](https://redis.io/docs/latest/operate/rs/databases/configure/)

## Troubleshooting

### Common Issues

1. **Database Creation Fails**: 
   - Check cluster is fully operational (`rladmin status`)
   - Verify REST API credentials are correct
   - Ensure port is available and in valid range

2. **Private Endpoints Not Available**:
   - Verify cluster was created with `register_dns_suffix` flag
   - Check DNS wildcard records for internal endpoints
   - Confirm external addresses are set on all nodes

3. **Database Won't Activate**:
   - Check memory availability on cluster nodes
   - Verify no port conflicts with existing databases
   - Review Redis Enterprise logs for detailed errors

### Debug Commands

```bash
# Check database status
sudo /opt/redislabs/bin/rladmin status databases

# View detailed database information
sudo /opt/redislabs/bin/rladmin info db <db-name>

# Test database connectivity
redis-cli -h <endpoint> -p <port> ping

# Check cluster resource availability
sudo /opt/redislabs/bin/rladmin status
```

## Usage Example

This module is automatically called by the main terraform configuration:

```hcl
module "database_management" {
  source = "./modules/application/database_management"

  name_prefix          = var.name_prefix
  platform             = var.platform
  ssh_private_key_path = var.ssh_private_key_path
  hosted_zone_name     = data.aws_route53_zone.main.name
  
  # Instance information
  public_ips = module.redis_instances.public_ips
  
  # Cluster credentials
  cluster_username = var.cluster_username
  cluster_password = var.cluster_password
  
  # Database configuration
  create_sample_database = var.create_sample_database
  sample_db_name        = var.sample_db_name
  sample_db_port        = var.sample_db_port
  sample_db_memory      = var.sample_db_memory
  
  # Dependencies
  cluster_verification_id = module.cluster_bootstrap.cluster_verification
}
```

This module provides a robust foundation for Redis database creation with full private/public endpoint support, enabling applications to connect securely and efficiently based on their deployment context.