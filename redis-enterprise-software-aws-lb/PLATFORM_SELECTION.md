# Platform Selection Guide

This Terraform configuration supports deployment on both Ubuntu and Red Hat Enterprise Linux (RHEL) platforms.

## Supported Platforms

### Ubuntu 22.04 LTS (Default)
- **AMI**: Latest Ubuntu 22.04 LTS (Jammy Jellyfish) HVM SSD
- **User**: `ubuntu`
- **Package Type**: `.deb` package or `.tar` archive
- **Default Download URL**: Uses official Ubuntu `.deb` package when available
- **DNS Configuration**: Uses `systemd-resolved` management

### Red Hat Enterprise Linux 9 (Free Tier)
- **AMI**: Latest RHEL 9 HVM (Free tier - Access2-GP3)
- **User**: `ec2-user`  
- **Package Type**: `.tar` archive
- **Download URL**: Must be specified by user in terraform.tfvars
- **Firewall**: Automatic `firewalld` configuration
- **DNS Configuration**: Manual `/etc/resolv.conf` management

## Configuration

### Automatic Platform Selection

Set the platform in `terraform.tfvars`:

```hcl
# Choose platform: "ubuntu" or "rhel"
platform = "ubuntu"    # Default
# or
platform = "rhel"      # For Red Hat Enterprise Linux 9

# Specify your desired Redis Enterprise version URL
re_download_url = "https://your-redis-download-url"
```

### Specifying Download URL

You must specify the Redis Enterprise download URL in your terraform.tfvars:

```hcl
platform = "rhel"
# Specify your desired Redis Enterprise version URL
re_download_url = "https://your-redis-download-url-for-rhel"
```

#### Finding Download URLs:

Visit the official Redis documentation to find download URLs for your desired version:
**https://redis.io/docs/latest/operate/rs/installing-upgrading/install/plan-deployment/supported-platforms/**

Choose the appropriate download URL based on:
- Your selected platform (Ubuntu/RHEL)
- Your desired Redis Enterprise version
- Your system architecture (typically x86_64)

## Platform-Specific Features

### Ubuntu-Specific Features
- Automatic package dependency resolution with `apt-get install -f`
- `systemd-resolved` service management for DNS port 53
- Supports both `.deb` packages and `.tar` archives
- Uses Ubuntu's standard package management tools

### RHEL-Specific Features
- Automatic firewall configuration with `firewalld`
- Package installation via `dnf` package manager
- RHEL-specific system optimizations
- Manual DNS configuration for Redis Enterprise DNS servers
- Firewall ports automatically opened:
  - Redis Enterprise UI: 8443, 8080
  - Redis Enterprise API: 9443, 9081
  - Cluster communication: 8001, 8070-8071
  - DNS: 53 (TCP/UDP), 5353 (TCP/UDP)
  - Database ports: 10000-19999

## AMI Selection

The configuration automatically selects the appropriate AMI based on your platform choice:

- **Ubuntu**: Uses Canonical's official Ubuntu 22.04 LTS AMI
- **RHEL**: Uses Red Hat's official RHEL 9 AMI with hourly billing

## Installation Scripts

Platform-specific installation scripts handle the differences:

- `install_redis_enterprise_ubuntu.sh`: Ubuntu-specific installation
- `install_redis_enterprise_rhel.sh`: RHEL-specific installation with firewall configuration

## SSH Access

The system automatically uses the correct SSH user based on platform:

- **Ubuntu**: `ubuntu` user
- **RHEL**: `ec2-user` user

## Switching Platforms

To switch between platforms:

1. Update `terraform.tfvars`:
   ```hcl
   platform = "rhel"  # or "ubuntu"
   ```

2. Run Terraform:
   ```bash
   terraform plan
   terraform apply
   ```

The configuration will automatically:
- Select the appropriate AMI
- Use the correct SSH user
- Apply platform-specific optimizations
- Configure platform-specific services (DNS, firewall)

## Firewall Configuration (RHEL Only)

For RHEL deployments, the firewall is automatically configured with the following ports:

```bash
# Redis Enterprise cluster communication
sudo firewall-cmd --permanent --add-port=8001/tcp --add-port=8070-8071/tcp
sudo firewall-cmd --permanent --add-port=9081/tcp --add-port=9443/tcp
sudo firewall-cmd --permanent --add-port=8443/tcp --add-port=8080/tcp

# DNS services
sudo firewall-cmd --permanent --add-port=53/tcp --add-port=53/udp
sudo firewall-cmd --permanent --add-port=5353/tcp --add-port=5353/udp

# Database access ports
sudo firewall-cmd --permanent --add-port=10000-19999/tcp

# Reload firewall rules
sudo firewall-cmd --reload
```

For Ubuntu, the default UFW firewall is typically inactive, but you can enable it if needed after deployment.

## Troubleshooting

### Check Platform Configuration
```bash
# View selected AMI and platform
terraform show | grep ami
terraform show | grep platform
```

### Check Installation Logs
```bash
# SSH to any node and check logs
ssh -i your-key.pem ubuntu@<node-ip>  # Ubuntu
ssh -i your-key.pem ec2-user@<node-ip>  # RHEL

# Check installation logs
sudo tail -f /var/log/redis-enterprise-install.log
sudo tail -f /var/log/basic-setup.log
```

### Verify Firewall (RHEL only)
```bash
# Check firewall status and rules
sudo firewall-cmd --list-all
sudo firewall-cmd --list-ports
```

## Cost Considerations

- **Ubuntu**: Generally lower cost, uses community AMI
- **RHEL**: Uses free tier AMI (Access2-GP3) which includes no additional Red Hat subscription costs for development/testing

Both platforms provide identical Redis Enterprise functionality and performance. The RHEL free tier is suitable for development and testing workloads.