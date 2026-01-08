# CRDB Management Scripts

This directory contains scripts for managing Redis Enterprise Active-Active (CRDB) databases.

## create-crdb.sh

Creates an Active-Active CRDB database across multiple Redis Enterprise clusters.

### Usage

#### Automatic (via Terraform)

The script is automatically called when you run:

```bash
terraform apply
```

Terraform passes the configuration via environment variables.

#### Manual (standalone)

You can also run the script manually for testing or troubleshooting:

```bash
# From the terraform root directory
cd /path/to/redis-enterprise-software-aws-aa

# Set credentials (optional - defaults to terraform.tfvars values)
export REDIS_USERNAME="admin@admin.com"
export REDIS_PASSWORD="your-password"

# Run the script
./modules/crdb_management/scripts/create-crdb.sh
```

The script will automatically read cluster information from `terraform output`.

### Features

- ✅ **Retry logic** - Retries failed operations with exponential backoff
- ✅ **Idempotent** - Safe to run multiple times (checks if CRDB exists)
- ✅ **Better error handling** - Clear error messages and proper exit codes
- ✅ **Cluster readiness checks** - Waits for clusters to be fully ready
- ✅ **Dual-mode** - Works both with Terraform and standalone

### Dependencies

- `bash` (version 4.0+)
- `curl`
- `jq` (for JSON parsing)

These are the same dependencies already required by the Terraform configuration.

### Environment Variables

When called by Terraform, these are set automatically:

- `CRDB_CONFIG_JSON` - Full CRDB configuration as JSON
- `CLUSTER_USERNAME` - Redis Enterprise cluster admin username
- `CLUSTER_PASSWORD` - Redis Enterprise cluster admin password

When run manually, the script reads from Terraform outputs and these optional env vars:

- `REDIS_USERNAME` - Override cluster username (default: from terraform.tfvars)
- `REDIS_PASSWORD` - Override cluster password (default: from terraform.tfvars)
- `CRDB_NAME` - Override CRDB name (default: active-active-db)
- `CRDB_PORT` - Override CRDB port (default: 12000)
- `CRDB_MEMORY` - Override memory size in bytes (default: 1073741824)

### Exit Codes

- `0` - Success (CRDB created or already exists)
- `1` - Error (cluster not ready, API error, etc.)

### Troubleshooting

#### Debug mode

Run with verbose output:

```bash
bash -x ./modules/crdb_management/scripts/create-crdb.sh
```

#### Check if CRDB exists

```bash
curl -k -u "admin@admin.com:password" \
  https://<cluster-ip>:9443/v1/crdbs | jq
```

#### Test cluster connectivity

```bash
curl -k -u "admin@admin.com:password" \
  https://<cluster-ip>:9443/v1/cluster
```

### Examples

#### Check CRDB status manually

```bash
# Export credentials
export REDIS_PASSWORD="your-password"

# Run script (will skip if exists)
./modules/crdb_management/scripts/create-crdb.sh
```

#### Force recreation (delete first)

```bash
# Delete CRDB via API
curl -k -u "admin@admin.com:password" \
  -X DELETE https://<cluster-ip>:9443/v1/crdbs/1

# Re-run script
./modules/crdb_management/scripts/create-crdb.sh
```

## Future Scripts

Additional scripts that could be added:

- `delete-crdb.sh` - Safely delete CRDB from all clusters
- `update-crdb.sh` - Modify CRDB configuration
- `verify-crdb.sh` - Comprehensive CRDB health check
- `backup-crdb.sh` - Backup CRDB configuration and data
