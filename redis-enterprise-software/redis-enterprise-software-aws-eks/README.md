# Redis Enterprise Software on AWS EKS

Deploy a production-ready Redis Enterprise Software cluster on Amazon EKS (Elastic Kubernetes Service) with automated operator deployment, persistent storage, and high availability across availability zones.

## 🚀 Quick Start

### 1. Prerequisites
- **AWS Account** with credentials configured (`aws configure`)
- **Terraform** >= 1.0
- **kubectl** >= 1.23
- **AWS CLI** configured

### 2. Deploy in 3 Steps

```bash
# 1. Clone and configure
cd redis-enterprise-software-aws-eks
cp terraform.tfvars.example terraform.tfvars

# 2. Edit terraform.tfvars (see Configuration section)
# Required: user_prefix, owner, redis_cluster_username, redis_cluster_password

# 3. Deploy
terraform init
terraform plan
terraform apply
```

### 3. Access Your Cluster

After deployment (~10-15 minutes), configure kubectl and access your cluster:

**Note:** Services use ClusterIP (internal access) per Redis Enterprise Kubernetes documentation.

```bash
# Configure kubectl
aws eks update-kubeconfig --region us-west-2 --name your-prefix-redis-ent-eks

# Verify cluster status
kubectl get rec -n redis-enterprise
kubectl get pods -n redis-enterprise
kubectl get svc -n redis-enterprise

# Access Redis Enterprise UI (via port-forward)
kubectl port-forward -n redis-enterprise svc/redis-ent-eks-ui 8443:8443
# Then access: https://localhost:8443

# Access sample database (via port-forward)
kubectl port-forward -n redis-enterprise svc/demo 12000:12000
redis-cli -h localhost -p 12000

# Or deploy an app in the cluster to access Redis internally:
# Service FQDN: demo.redis-enterprise.svc.cluster.local:12000
```

## ⚙️ Configuration

### Required Variables

```hcl
# Project Settings
user_prefix  = "your-name"           # Your unique identifier
cluster_name = "redis-ent-eks"       # Cluster name
owner        = "your-name"           # Owner tag

# AWS Configuration
aws_region = "us-west-2"

# Redis Enterprise Credentials
redis_cluster_username = "admin@admin.com"
redis_cluster_password = "YourSecurePassword123"  # Alphanumeric only, min 8 chars
```

### Optional Settings

```hcl
# Kubernetes Version
kubernetes_version = "1.28"          # 1.23 - 1.33 supported

# Worker Nodes
node_instance_types = ["t3.xlarge"]  # 16GB RAM per node
node_desired_size   = 3              # Minimum 3 for HA
node_min_size       = 3
node_max_size       = 6

# Redis Enterprise Cluster
redis_cluster_nodes  = 3             # Number of Redis nodes
redis_cluster_memory = "4Gi"         # Memory per node
redis_cluster_storage_size = "50Gi"  # Storage per node

# Sample Database
create_sample_database = true
sample_db_name         = "demo"
sample_db_port         = 12000
sample_db_memory       = "100MB"
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          AWS Account                                │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │                      Amazon VPC                                │ │
│  │                                                                │ │
│  │  ┌──────────────────────────────────────────────────────────┐ │ │
│  │  │              EKS Control Plane (Managed)                  │ │ │
│  │  └──────────────────────────────────────────────────────────┘ │ │
│  │                                                                │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │ │
│  │  │   AZ-1       │  │   AZ-2       │  │   AZ-3       │        │ │
│  │  │              │  │              │  │              │        │ │
│  │  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │        │ │
│  │  │ │ Worker   │ │  │ │ Worker   │ │  │ │ Worker   │ │        │ │
│  │  │ │ Node 1   │ │  │ │ Node 2   │ │  │ │ Node 3   │ │        │ │
│  │  │ │          │ │  │ │          │ │  │ │          │ │        │ │
│  │  │ │ Redis    │ │  │ │ Redis    │ │  │ │ Redis    │ │        │ │
│  │  │ │ Pod 1    │ │  │ │ Pod 2    │ │  │ │ Pod 3    │ │        │ │
│  │  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │        │ │
│  │  │              │  │              │  │              │        │ │
│  │  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │        │ │
│  │  │ │ EBS Vol  │ │  │ │ EBS Vol  │ │  │ │ EBS Vol  │ │        │ │
│  │  │ │ (gp3)    │ │  │ │ (gp3)    │ │  │ │ (gp3)    │ │        │ │
│  │  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │        │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘        │ │
│  │                                                                │ │
│  │  ┌──────────────────────────────────────────────────────────┐ │ │
│  │  │              LoadBalancers (UI + Databases)               │ │ │
│  │  └──────────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

**Key Components:**
- **EKS Control Plane**: Managed Kubernetes master nodes (AWS-managed)
- **Worker Nodes**: EC2 instances running Redis Enterprise pods (3+ nodes)
- **Redis Enterprise Operator**: Manages cluster lifecycle via Kubernetes CRDs
- **EBS CSI Driver**: Provides persistent storage for Redis data
- **ClusterIP Services**: Internal-only access (per Redis Enterprise K8s docs)
- **Multi-AZ HA**: Rack awareness ensures pods distributed across AZs

## 🔧 What Gets Deployed

### AWS Infrastructure
1. **VPC & Networking**
   - VPC with public/private subnets across 3 AZs
   - Internet Gateway for public access
   - Route tables and subnet associations
   - Security groups for EKS cluster and nodes

2. **EKS Cluster**
   - Managed Kubernetes control plane (v1.28)
   - OIDC provider for IAM integration
   - Cluster addons: vpc-cni, coredns, kube-proxy
   - CloudWatch logging enabled

3. **EKS Node Group**
   - 3+ EC2 worker nodes (t3.xlarge by default)
   - Auto-scaling group configuration
   - Launch template with encrypted EBS volumes
   - IAM roles and policies

4. **EBS CSI Driver**
   - AWS EBS CSI driver addon
   - gp3 storage class (default)
   - IRSA (IAM Roles for Service Accounts)

### Kubernetes Resources
1. **Redis Enterprise Operator**
   - Deployed via Helm chart
   - Manages RedisEnterpriseCluster (REC) and RedisEnterpriseDatabase (REDB) CRDs
   - Automatic reconciliation and health monitoring

2. **Redis Enterprise Cluster (REC)**
   - 3-node cluster with rack awareness
   - Persistent volumes for each node
   - Admin credentials stored in Kubernetes secrets
   - ClusterIP service for UI access (port 8443)

3. **Sample Database (REDB)** - Optional
   - Redis database for testing
   - Replication enabled
   - ClusterIP service for internal database access
   - Configurable memory and persistence

## 📊 Deployment Timeline

- **EKS Cluster**: ~8-10 minutes
- **Node Group**: ~3-5 minutes
- **EBS CSI Driver**: ~1-2 minutes
- **Redis Operator**: ~1 minute
- **Redis Cluster**: ~3-5 minutes
- **Sample Database**: ~1-2 minutes
- **Total**: ~15-20 minutes

## 🔍 Management

### Useful Commands

```bash
# Configure kubectl for your cluster
aws eks update-kubeconfig --region us-west-2 --name your-prefix-redis-ent-eks

# View Redis Enterprise cluster status
kubectl get rec -n redis-enterprise
kubectl describe rec redis-ent-eks -n redis-enterprise

# View Redis databases
kubectl get redb -n redis-enterprise

# View all pods
kubectl get pods -n redis-enterprise

# View services (to get LoadBalancer endpoints)
kubectl get svc -n redis-enterprise

# View operator logs
kubectl logs -n redis-enterprise -l name=redis-enterprise-operator --tail=100

# View cluster logs
kubectl logs -n redis-enterprise -l app=redis-enterprise --tail=100

# Access Redis Enterprise pod directly
kubectl exec -it redis-ent-eks-0 -n redis-enterprise -- bash

# Get admin password
kubectl get secret redis-ent-eks-admin-credentials -n redis-enterprise \
  -o jsonpath='{.data.password}' | base64 -d
```

### Accessing the UI

**Internal Access (from pods in cluster):**
```bash
# Service FQDN
redis-ent-eks-ui.redis-enterprise.svc.cluster.local:8443
```

**Local Access (via port-forward):**
```bash
# Port-forward to your local machine
kubectl port-forward -n redis-enterprise svc/redis-ent-eks-ui 8443:8443

# Access at: https://localhost:8443
```

- **Username**: Your configured admin email
- **Password**: Your configured password
- **Note**: Browser will show certificate warning (self-signed cert) - this is expected

### Connecting to Databases

**From inside the cluster (applications running as pods):**
```bash
# Service FQDN format
<database-name>.<namespace>.svc.cluster.local:<port>

# Example for demo database
redis-cli -h demo.redis-enterprise.svc.cluster.local -p 12000

# Test from a temporary pod
kubectl run redis-test --image=redis:latest -n redis-enterprise --rm -it -- bash
redis-cli -h demo -p 12000 PING
# Response: PONG
```

**Local Access (via port-forward):**
```bash
# Port-forward database service
kubectl port-forward -n redis-enterprise svc/demo 12000:12000

# Connect locally
redis-cli -h localhost -p 12000
```

### Creating Additional Databases

Create a file `my-database.yaml`:

```yaml
apiVersion: app.redislabs.com/v1alpha1
kind: RedisEnterpriseDatabase
metadata:
  name: my-app-db
  namespace: redis-enterprise
spec:
  redisEnterpriseCluster:
    name: redis-ent-eks
  memorySize: 1GB
  databasePort: 12001
  replication: true
  persistence: aofEveryOneSecond
  databaseServiceType: LoadBalancer
```

Apply it:
```bash
kubectl apply -f my-database.yaml
```

## 🚨 Troubleshooting

### Common Issues

1. **Operator pod not starting**
   ```bash
   kubectl describe pod -n redis-enterprise -l name=redis-enterprise-operator
   # Check events for errors
   ```

2. **Redis cluster pods stuck in Pending**
   ```bash
   kubectl describe pod -n redis-enterprise redis-ent-eks-0
   # Common issue: insufficient node resources or storage
   ```

3. **Storage issues**
   ```bash
   kubectl get pvc -n redis-enterprise
   kubectl get storageclass
   # Verify EBS CSI driver is running
   kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver
   ```

4. **Can't access services**
   ```bash
   kubectl get svc -n redis-enterprise
   # Verify services are ClusterIP type
   # Use kubectl port-forward for local access
   # For in-cluster access, use service FQDN: <svc>.<namespace>.svc.cluster.local
   ```

5. **Cluster not becoming ready**
   ```bash
   kubectl logs -n redis-enterprise redis-ent-eks-0 -c redis-enterprise-node
   # Check for licensing or configuration issues
   ```

### Getting Help

```bash
# Full cluster state
kubectl get all -n redis-enterprise

# Operator status
kubectl get deployment -n redis-enterprise redis-enterprise-operator

# Cluster validation
kubectl get rec redis-ent-eks -n redis-enterprise -o yaml

# Events
kubectl get events -n redis-enterprise --sort-by='.lastTimestamp'
```

## 🌐 Adding External Access (Optional)

By default, services use ClusterIP for internal-only access (per Redis Enterprise K8s docs).

### To Add External Access via Ingress:

1. **Install NGINX Ingress Controller**
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/aws/deploy.yaml
   ```

2. **Create Ingress Resource**
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: redis-demo-ingress
     namespace: redis-enterprise
     annotations:
       kubernetes.io/ingress.class: nginx
       nginx.ingress.kubernetes.io/ssl-passthrough: "true"
   spec:
     rules:
     - host: redis-demo.yourdomain.com
       http:
         paths:
         - path: /
           pathType: ImplementationSpecific
           backend:
             service:
               name: demo
               port:
                 name: redis
   ```

3. **Update DNS**
   - Point `redis-demo.yourdomain.com` to the Ingress LoadBalancer endpoint
   - Get endpoint: `kubectl get svc -n ingress-nginx ingress-nginx-controller`

See [Redis Enterprise Kubernetes Networking docs](https://redis.io/docs/latest/operate/kubernetes/networking/) for details.

## 🔒 Security Notes

### Production Recommendations

1. **Network Security**
   - Use private subnets for worker nodes (enable NAT gateway)
   - Restrict security group rules to specific IP ranges
   - Implement Kubernetes network policies

2. **Secrets Management**
   - Use AWS Secrets Manager or Systems Manager Parameter Store
   - Enable encryption at rest for secrets
   - Rotate credentials regularly

3. **Access Control**
   - Enable EKS cluster endpoint private access only
   - Use IAM roles for service accounts (IRSA)
   - Implement RBAC policies

4. **Monitoring & Logging**
   - Enable EKS control plane logging
   - Deploy Prometheus/Grafana for metrics
   - Configure CloudWatch alarms
   - Set up audit logging

5. **TLS/SSL**
   - Enable TLS for Redis databases
   - Use valid SSL certificates (not self-signed)
   - Configure TLS for cluster communication

## 📈 Scaling

### Horizontal Scaling

```bash
# Scale EKS node group
aws eks update-nodegroup-config \
  --cluster-name your-prefix-redis-ent-eks \
  --nodegroup-name your-prefix-redis-ent-eks-node-group \
  --scaling-config desiredSize=5

# Scale Redis Enterprise cluster (edit REC)
kubectl edit rec redis-ent-eks -n redis-enterprise
# Change spec.nodes to desired count
```

### Vertical Scaling

Update `terraform.tfvars`:
```hcl
node_instance_types = ["r6i.xlarge"]  # Change instance type
redis_cluster_memory = "8Gi"          # Increase memory
```

Then apply:
```bash
terraform apply
```

## 💰 Cost Optimization

### Development/Testing
- Use t3.xlarge instances
- 3 nodes minimum
- gp3 storage (most cost-effective)
- Destroy when not in use: `terraform destroy`

### Production
- Use reserved instances or Savings Plans
- Consider r6i instances (memory-optimized)
- Enable cluster autoscaling
- Monitor and rightsize resources

## 📝 Module Structure

```
.
├── main.tf                      # Main orchestration
├── variables.tf                 # Input variables
├── outputs.tf                   # Output values
├── provider.tf                  # Provider configuration
├── versions.tf                  # Provider versions
├── terraform.tfvars.example     # Configuration template
├── README.md                    # This file
└── modules/
    ├── vpc/                     # VPC and networking
    ├── eks_cluster/             # EKS control plane
    ├── eks_node_group/          # EKS worker nodes
    ├── ebs_csi_driver/          # EBS CSI driver and storage class
    ├── redis_operator/          # Redis Enterprise operator (Helm)
    ├── redis_cluster/           # Redis Enterprise cluster (REC)
    └── redis_database/          # Redis database (REDB)
```

## 🔗 Additional Resources

- [Redis Enterprise on Kubernetes Documentation](https://redis.io/docs/latest/operate/kubernetes/)
- [Supported Kubernetes Distributions](https://redis.io/docs/latest/operate/kubernetes/reference/supported_k8s_distributions/)
- [Redis Enterprise Kubernetes Architecture](https://redis.io/docs/latest/operate/kubernetes/architecture/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Redis Enterprise Operator GitHub](https://github.com/RedisLabs/redis-enterprise-k8s-docs)

---

**⚠️ Important**: This creates real AWS resources that incur costs (~$400-500/month for dev/test). Remember to run `terraform destroy` when done testing.
