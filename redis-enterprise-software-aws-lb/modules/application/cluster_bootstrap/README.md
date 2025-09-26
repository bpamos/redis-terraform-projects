# Redis Enterprise Cluster Bootstrap Module

This module handles the automated creation and configuration of a Redis Enterprise cluster on AWS, including both primary and replica node setup with private/public endpoint support.

## Overview

The cluster bootstrap process follows Redis Enterprise best practices to create a production-ready cluster with high availability and proper networking configuration.

## What This Module Does

### 1. **Primary Node Cluster Creation**
- Creates the initial Redis Enterprise cluster on the first node (node 1)
- Configures cluster with external address for private/public endpoint support
- Sets up DNS suffix registration for internal endpoint resolution
- Waits for cluster to be fully operational before proceeding

### 2. **Replica Node Joining** 
- Joins additional nodes (node 2, 3, etc.) to the cluster
- Configures external addresses on each node for dual endpoint support
- Verifies successful cluster membership for each node
- Handles both private IP communication and public IP fallback

### 3. **Final Cluster Verification**
- Performs comprehensive cluster health checks
- Validates all nodes are properly joined and operational
- Confirms cluster state is ready for database creation

## Redis Enterprise Cluster Creation Process

### Step 1: Cluster Creation Command
```bash
sudo /opt/redislabs/bin/rladmin cluster create \
  name <cluster-fqdn> \
  username <admin-email> \
  password <admin-password> \
  register_dns_suffix \
  rack_aware \
  rack_id <availability-zone>
```

**Key Parameters:**
- `name`: Full cluster FQDN (e.g., `redis-cluster.example.com`)
- `username`: Cluster admin username (email format)
- `password`: Cluster admin password
- `register_dns_suffix`: **Critical flag** that enables private endpoint support
- `rack_aware`: Enables rack/zone awareness for high availability
- `rack_id`: Availability zone ID for the primary node (e.g., `us-west-2a`)

### Step 2: External Address Configuration
```bash
sudo /opt/redislabs/bin/rladmin node <node-id> external_addr set <public-ip>
```

This command configures each node with both internal and external IP addresses, enabling:
- **Private endpoints**: `database-internal.cluster.com` (VPC access)
- **Public endpoints**: `database.cluster.com` (Internet access)

### Step 3: Node Joining Process
```bash
sudo /opt/redislabs/bin/rladmin cluster join \
  nodes <primary-private-ip> \
  username <admin-email> \
  password <admin-password> \
  rack_id <availability-zone>
```

**Key Parameters:**
- `nodes`: Primary node's private IP address for internal cluster communication
- `rack_id`: Availability zone ID for the joining node (e.g., `us-west-2b`)

Each node is assigned to its specific availability zone to ensure high availability and proper replica distribution across AWS availability zones.

## Private/Public Endpoint Configuration

This module implements Redis Enterprise's dual endpoint architecture following the official documentation:

### Key Requirements for Private Endpoints

1. **`register_dns_suffix` Flag**: Must be set during initial cluster creation
   - Enables Redis Enterprise to create both internal and external DNS mappings
   - Cannot be added after cluster creation - must be configured initially

2. **External Address Configuration**: Each node must have external addresses set
   - Allows Redis Enterprise to serve both private and public endpoints
   - Configured via `rladmin node external_addr set` command

3. **DNS Wildcard Records**: DNS must be configured to support both endpoint types
   - `*.cluster.domain.com` → Public IP (for external access)
   - `*-internal.cluster.domain.com` → Private IP (for VPC access)

## Dependencies

This module depends on:
- **Redis Enterprise Installation**: Must be completed on all nodes
- **Network Connectivity**: Nodes must be able to communicate on cluster ports
- **DNS Configuration**: Proper DNS records for cluster FQDN resolution

## Cluster Communication Ports

Redis Enterprise requires these ports for proper cluster operation:
- **8001**: Cluster management
- **8070-8071**: Cluster communication  
- **9443**: HTTPS API
- **10000-19999**: Database ports
- **20000-29999**: Shard replication ports

## Implementation Details

### Platform Support
- **Ubuntu 22.04**: Uses `ubuntu` SSH user
- **RHEL 9**: Uses `ec2-user` SSH user
- Automatic platform detection and SSH user selection

### Error Handling
- Timeout protection for all cluster operations
- Retry logic for cluster state verification
- Comprehensive status checking at each step

### Security
- Cluster passwords stored in temporary files during execution
- Immediate cleanup of credential files after use
- SSH key-based authentication for all operations

## Outputs

The module provides:
- `cluster_verification`: ID for dependency chaining with database creation
- Cluster status verification for downstream modules

## Redis Enterprise Documentation References

This implementation follows official Redis Enterprise documentation:

- **Cluster Setup**: [Installing Redis Enterprise on Linux](https://redis.io/docs/latest/operate/rs/installing-upgrading/install/install-on-linux/)
- **Private/Public Endpoints**: [Private and Public Endpoints](https://redis.io/docs/latest/operate/rs/networking/private-public-endpoints/)
- **Multi-IP Configuration**: [Multi-IP and IPv6 Support](https://redis.io/docs/latest/operate/rs/networking/multi-ip-ipv6/)
- **AWS DNS Configuration**: [Configuring Route53 DNS](https://redis.io/docs/latest/operate/rs/networking/configuring-aws-route53-dns-redis-enterprise/)

## Usage Example

This module is automatically called by the main terraform configuration:

```hcl
module "cluster_bootstrap" {
  source = "./modules/application/cluster_bootstrap"

  name_prefix          = var.name_prefix
  node_count           = var.node_count
  platform             = var.platform
  ssh_private_key_path = var.ssh_private_key_path
  hosted_zone_name     = data.aws_route53_zone.main.name
  
  # Cluster configuration
  cluster_username = var.cluster_username
  cluster_password = var.cluster_password
  rack_awareness   = var.rack_awareness
  flash_enabled    = var.flash_enabled
  
  # Instance information
  instance_ids = module.redis_instances.instance_ids
  public_ips   = module.redis_instances.public_ips
  private_ips  = module.redis_instances.private_ips
  
  # Dependencies
  installation_completion_ids = module.redis_enterprise_install.installation_completion_ids
}
```

## Troubleshooting

### Common Issues

1. **Cluster Creation Fails**: Check that Redis Enterprise installation completed successfully
2. **Node Join Fails**: Verify network connectivity between nodes on required ports
3. **Private Endpoints Missing**: Ensure `register_dns_suffix` flag was set during cluster creation

### Debug Commands

```bash
# Check cluster status
sudo /opt/redislabs/bin/rladmin status

# View cluster information
sudo /opt/redislabs/bin/rladmin info cluster

# Check node external addresses
sudo /opt/redislabs/bin/rladmin info node
```

This module ensures a robust, production-ready Redis Enterprise cluster with full private/public endpoint support following Redis Enterprise best practices.