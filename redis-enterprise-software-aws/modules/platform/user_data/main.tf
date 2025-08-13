# =============================================================================
# PLATFORM USER DATA GENERATION
# =============================================================================
# Generates platform-specific user data for basic system setup
# =============================================================================

# Local values for platform-specific configuration
locals {
  platform_scripts = {
    ubuntu = "basic_setup_ubuntu.sh"
    rhel   = "basic_setup_rhel.sh"
  }
  
  selected_script = local.platform_scripts[var.platform]
}

# Generate user data for the specified platform using templatefile function
locals {
  user_data_rendered = templatefile("${path.module}/scripts/${local.selected_script}", {
    hostname = var.hostname
    platform = var.platform
  })
}