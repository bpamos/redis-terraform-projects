# Redis Enterprise Download URLs

## Important: User-Provided Download URLs

This Terraform configuration **requires users to specify** the Redis Enterprise download URL in their `terraform.tfvars` file. This approach:

✅ **Allows version flexibility** - Users can deploy any Redis Enterprise version they need  
✅ **Enables latest versions** - Users can always use the most current Redis Enterprise release  
✅ **Avoids hardcoded URLs** - No outdated URLs committed to the repository  
✅ **Maintains security** - No specific download URLs exposed in public code  

## How to Find Download URLs

1. **Visit Redis Documentation:**
   https://redis.io/docs/latest/operate/rs/installing-upgrading/install/plan-deployment/supported-platforms/

2. **Choose based on your platform:**
   - Ubuntu 22.04 LTS: Look for Jammy/Ubuntu packages
   - RHEL 9: Look for RHEL 9 packages  
   - RHEL 8: Look for RHEL 8 packages

3. **Copy the download URL** to your `terraform.tfvars`:
   ```hcl
   # Example for Ubuntu
   platform = "ubuntu"
   re_download_url = "https://your-redis-download-url.tar"
   
   # Example for RHEL
   platform = "rhel" 
   re_download_url = "https://your-redis-rhel-download-url.tar"
   ```

## Validation

The configuration includes validation to ensure:
- Download URL is not empty
- URL uses HTTPS protocol
- URL is properly formatted

If you don't provide a valid URL, Terraform will show an error message with guidance.

## Example terraform.tfvars

See `terraform.tfvars.example` for a complete example with placeholder URLs that you should replace with current Redis Enterprise download URLs from the official Redis documentation.