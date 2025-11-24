#==============================================================================
# REDIS ENTERPRISE CLUSTER CREDENTIALS SECRET
#==============================================================================

resource "kubernetes_secret" "redis_enterprise_admin" {
  metadata {
    name      = "${var.cluster_name}-admin-credentials"
    namespace = var.namespace
  }

  data = {
    username = base64encode(var.admin_username)
    password = base64encode(var.admin_password)
  }

  type = "Opaque"
}

# Bulletin board configmap required by bootstrapper
resource "kubernetes_config_map" "bulletin_board" {
  metadata {
    name      = "${var.cluster_name}-bulletin-board"
    namespace = var.namespace
  }

  data = {
    BulletinBoard = ""
  }
}

#==============================================================================
# REDIS ENTERPRISE CLUSTER (REC)
#==============================================================================

resource "kubectl_manifest" "redis_enterprise_cluster" {
  yaml_body = <<-YAML
    apiVersion: app.redislabs.com/v1
    kind: RedisEnterpriseCluster
    metadata:
      name: ${var.cluster_name}
      namespace: ${var.namespace}
      ${length(var.ui_service_annotations) > 0 ? "annotations:\n" + join("\n", [for k, v in var.ui_service_annotations : "        ${k}: \"${v}\""]) : ""}
    spec:
      nodes: ${var.node_count}

      # Resource allocation per node
      redisEnterpriseNodeResources:
        limits:
          cpu: "${var.node_cpu_limit}"
          memory: ${var.node_memory_limit}
        requests:
          cpu: "${var.node_cpu_request}"
          memory: ${var.node_memory_request}

      # Persistent storage configuration
      persistentSpec:
        enabled: true
        storageClassName: "${var.storage_class_name}"
        volumeSize: ${var.storage_size}

      # Admin credentials
      username: ${var.admin_username}

      # UI service configuration
      uiServiceType: ${var.ui_service_type}

      # Rack awareness for HA (distributes nodes across AZs)
      rackAwarenessNodeLabel: "topology.kubernetes.io/zone"

      # Additional configuration
      redisEnterpriseImageSpec:
        imagePullPolicy: IfNotPresent
        versionTag: ${var.redis_enterprise_version_tag}

      ${var.license_secret_name != "" ? "# License configuration\n      licenseSecretName: ${var.license_secret_name}" : ""}

      ${var.enable_ingress ? <<-INGRESS
      # Ingress/Route configuration for external access
      ingressOrRouteSpec:
        apiFqdnUrl: ${var.api_fqdn_url}
        dbFqdnSuffix: ${var.db_fqdn_suffix}
        method: ${var.ingress_method}
        ${var.ingress_method == "ingress" ? "ingressAnnotations:\n          ${join("\n          ", [for k, v in var.ingress_annotations : "${k}: \"${v}\""])}" : ""}
      INGRESS
: ""}
  YAML

depends_on = [
  kubernetes_secret.redis_enterprise_admin
]
}

#==============================================================================
# WAIT FOR CLUSTER TO BE READY
#==============================================================================

resource "time_sleep" "wait_for_cluster" {
  depends_on = [kubectl_manifest.redis_enterprise_cluster]

  create_duration = "180s" # Wait 3 minutes for cluster to become ready
}
