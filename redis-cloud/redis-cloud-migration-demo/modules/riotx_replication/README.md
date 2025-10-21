# RIOT-X Replication Module

Configures and starts RIOT-X live replication from ElastiCache to Redis Cloud with comprehensive monitoring and error handling.

## Features

- **🔄 Live Replication**: Real-time data sync from ElastiCache to Redis Cloud
- **⚙️ Configurable Modes**: Support for LIVE, STREAM, and SNAPSHOT replication
- **📊 Built-in Metrics**: Optional Prometheus metrics collection
- **🔍 Connectivity Validation**: Pre-flight checks before starting replication
- **📝 Enhanced Logging**: Detailed logging with timestamps and configuration details
- **💻 Easy Monitoring**: SSH commands and URLs provided in outputs

## Usage

### Basic Usage
```hcl
module "riotx_replication" {
  source = "./modules/riotx_replication"
  
  # Required parameters
  ec2_public_ip               = module.ec2_riot.public_ip
  ssh_private_key_path        = var.ssh_private_key_path
  elasticache_endpoint        = module.elasticache_standalone_ksn.primary_endpoint
  rediscloud_private_endpoint = module.rediscloud.database_private_endpoint
  rediscloud_password         = module.rediscloud.rediscloud_password
  
  depends_on = [
    module.elasticache_standalone_ksn,
    module.rediscloud,
    module.rediscloud_peering,
    module.ec2_riot
  ]
}
```

### Advanced Configuration
```hcl
module "riotx_replication" {
  source = "./modules/riotx_replication"
  
  # Required parameters
  ec2_public_ip               = module.ec2_riot.public_ip
  ssh_private_key_path        = var.ssh_private_key_path
  elasticache_endpoint        = module.elasticache_standalone_ksn.primary_endpoint
  rediscloud_private_endpoint = module.rediscloud.database_private_endpoint
  rediscloud_password         = module.rediscloud.rediscloud_password
  
  # Optional configuration
  replication_mode = "LIVE"        # LIVE, STREAM, or SNAPSHOT
  enable_metrics   = true          # Enable Prometheus metrics
  metrics_port     = 8080          # Metrics endpoint port
  log_keys        = true           # Log individual key operations
}
```

## Configuration Options

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `replication_mode` | string | `"LIVE"` | Replication mode: LIVE, STREAM, or SNAPSHOT |
| `enable_metrics` | bool | `true` | Enable RIOT-X metrics collection |
| `metrics_port` | number | `8080` | Port for metrics endpoint |
| `log_keys` | bool | `true` | Enable detailed key logging |

## Outputs

The module provides comprehensive outputs for monitoring:

```hcl
# Access metrics (if enabled)
output "metrics_url" {
  value = module.riotx_replication.metrics_url
}

# Get monitoring commands
output "monitoring_commands" {
  value = module.riotx_replication.monitoring_commands
}

# Full replication configuration
output "replication_config" {
  value = module.riotx_replication.replication_config
}
```

## Monitoring

### View Live Logs
```bash
ssh ubuntu@<ec2-ip> 'tail -f /home/ubuntu/riotx.log'
```

### Check Replication Status
```bash
ssh ubuntu@<ec2-ip> 'ps aux | grep riotx'
```

### Access Metrics (if enabled)
```
http://<ec2-ip>:8080/metrics
```

## Requirements

- ✅ RIOT EC2 instance must be running and accessible
- ✅ ElastiCache must have keyspace notifications enabled  
- ✅ VPC peering must be established between AWS VPC and Redis Cloud
- ✅ SSH key must be accessible from Terraform execution environment
- ✅ Both Redis endpoints must be reachable from the RIOT EC2 instance

## Process Flow

1. **📤 Upload Script**: Uploads configured RIOT-X script to EC2 instance
2. **🔍 Validate Connectivity**: Tests connection to both ElastiCache and Redis Cloud
3. **🚀 Start Replication**: Launches RIOT-X replication in background
4. **📊 Enable Monitoring**: Exposes metrics and logging endpoints

## Important Notes

- **Continuous Operation**: Replication runs continuously until manually stopped
- **Background Process**: Uses `nohup` to ensure replication survives SSH disconnections
- **Error Handling**: Validates connectivity before starting replication
- **Resource Usage**: Monitor EC2 instance resources during large data migrations