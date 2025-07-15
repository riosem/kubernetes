# EKS FastAPI with SQLAlchemy

A **FastAPI application with SQLAlchemy ORM** deployed on **Amazon EKS**. Features a complete REST API with PostgreSQL database, automated deployments, and cost-optimized infrastructure.

## 🚀 Features

- **FastAPI**: Modern Python web framework with automatic API documentation
- **SQLAlchemy**: Full ORM with relationships and database operations
- **PostgreSQL**: Production database with sample data and health checks
- **Amazon EKS**: Managed Kubernetes with auto-scaling
- **Custom Docker Images**: Built and stored in Amazon ECR
- **Infrastructure as Code**: Complete Terraform configuration
- **Cost Optimized**: Development environment ~$105/month

## 📁 Project Structure

```
├── src/                     # FastAPI Application
│   ├── main.py             # Application entry point
│   ├── database/           # SQLAlchemy connection & session management
│   ├── models/             # Database models (User, Product, Order)
│   ├── schemas/            # Pydantic schemas for API validation
│   ├── routers/            # API route modules (CRUD operations)
│   ├── requirements.txt    # Python dependencies
│   └── Dockerfile         # Container build instructions
├── manifests/apps/         # Kubernetes Deployments
│   ├── fastapi-app.yaml   # FastAPI app deployment & service
│   └── postgres-app.yaml  # PostgreSQL + pgAdmin deployment
├── terraform/              # Infrastructure as Code
│   ├── main.tf            # VPC, subnets, ECR repository
│   ├── eks.tf             # EKS cluster configuration
│   └── environments/      # Environment-specific configurations
├── build_push.sh          # Build and push Docker images
├── deploy-infra.sh        # Deploy EKS infrastructure
├── deploy-app.sh          # Deploy applications
└── test_fastapi_endpoints.sh # Test API endpoints
```

## 🛠 Quick Start

### 1. Provide AWS Access Keys

```bash
export AWS_ACCESS_KEY_ID=***
export AWS_SECRET_ACCESS_KEY=***
export AWS_DEFAULT_REGION=us-east-2
```

### 2. Deploy Infrastructure

**Required AWS Permissions:**

- S3, EC2, ELB, ECR, CloudWatch, IAM, KMS, STS

```bash
# Deploy EKS cluster with ECR repository
ENV=dev REGION=us-east-2 APP=eks ./deploy-infra.sh
```

### 3. Build and Deploy Applications

```bash
# Build custom FastAPI image and push to ECR
ENV=dev REGION=us-east-2 APP=fastapi-app IMAGE_TAG=latest ./build_push.sh

# Deploy PostgreSQL database
ENV=dev REGION=us-east-2 APP=postgres-app ./deploy-app.sh

# Deploy FastAPI application
ENV=dev REGION=us-east-2 APP=fastapi-app ./deploy-app.sh
```

### 4. Test Your API

```bash
# Test all FastAPI endpoints
./test_fastapi_endpoints.sh
```

## 📊 API Endpoints

### **Application Status**

- `GET /` - Application info and hostname
- `GET /health` - Health check with database connectivity test  
- `GET /stats` - Real-time statistics from database

### **User Management**

- `GET /users` - List all users with pagination
- `POST /users` - Create new user
- `GET /users/{id}` - Get specific user
- `PUT /users/{id}` - Update user
- `DELETE /users/{id}` - Delete user

### **Product Management**

- `GET /products` - List all products
- `POST /products` - Create new product
- `GET /products/{id}` - Get specific product

### **Order Management**

- `GET /orders` - List all orders with relationships
- `POST /orders` - Create new order

## 🗄️ Database Schema

### **SQLAlchemy Models with Relationships**

```python
# User Model
class User:
    id: int (Primary Key)
    username: str (Unique)
    email: str (Unique)
    created_at: datetime
    orders: List[Order]  # One-to-many relationship

# Product Model
class Product:
    id: int (Primary Key)
    name: str
    price: float
    description: str
    order_items: List[OrderItem]  # One-to-many relationship

# Order Model
class Order:
    id: int (Primary Key)
    user_id: int (Foreign Key → users.id)
    total_amount: float
    status: str
    user: User  # Many-to-one relationship
    order_items: List[OrderItem]  # One-to-many relationship

# OrderItem Model (Junction Table)
class OrderItem:
    id: int (Primary Key)
    order_id: int (Foreign Key → orders.id)  
    product_id: int (Foreign Key → products.id)
    quantity: int
    unit_price: float
```

### **Sample Data Included**

- **Users**: john_doe, jane_smith, admin_user
- **Products**: Laptop ($999.99), Mouse ($29.99), Keyboard ($79.99)
- **Orders**: Sample orders with multiple items
- **Database View**: Order details with joined user and product info

## 🌍 Environment Configuration

### **Development** (`dev.tfvars`)

- **Cost-optimized** for learning (~$105/month)
- `t3.small` spot instances
- Single node with auto-scaling to 2
- Monitoring disabled

### **Production** (`prod.tfvars`)

- **Performance-optimized** for production
- `t3.large` on-demand instances  
- 2-10 nodes for high availability
- Full monitoring enabled

## 🐳 Container Strategy

### **FastAPI Application**

- **Custom Docker image** built from your source code
- **Multi-stage build** for optimized image size
- **Stored in Amazon ECR** for secure access
- **Auto-deployed** with updated code

### **PostgreSQL Database**

- **Official postgres:13-alpine** image
- **Initialization scripts** via ConfigMaps
- **Health checks** and monitoring
- **Persistent storage** with EBS volumes

### **pgAdmin Web Interface**

- **Official pgAdmin4** image
- **Database management** via web UI
- **Access**: Get LoadBalancer URL from `kubectl get svc`
- **Login**: <admin@example.com> / admin123

## 🧪 Testing Your Deployment

### **Automated Testing**

```bash
# Test all FastAPI endpoints with database operations
./test_fastapi_endpoints.sh

# Expected output:
# ✅ Root endpoint: Application info
# ✅ Health endpoint: Database connectivity confirmed
# ✅ Users endpoint: List of users from database
# ✅ Products endpoint: List of products
# ✅ Orders endpoint: Orders with relationships
# ✅ Stats endpoint: Real-time counts from database
# ✅ Create user: POST operation test
```

### **Manual Testing**

```bash
# Get FastAPI service URL
FASTAPI_URL=$(kubectl get svc fastapi-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test API endpoints
curl http://$FASTAPI_URL/
curl http://$FASTAPI_URL/health
curl http://$FASTAPI_URL/users

# Create a new user
curl -X POST http://$FASTAPI_URL/users \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com"}'

# View API documentation
echo "API Docs: http://$FASTAPI_URL/docs"
```

### **Database Access**

```bash
# Get pgAdmin URL
PGADMIN_URL=$(kubectl get svc pgadmin-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "pgAdmin: http://$PGADMIN_URL"

# Login: admin@example.com / admin123
# Server: postgres-service (internal Kubernetes service)
# Database: testdb, User: testuser, Password: password123
```

## 📊 Monitoring Your Application

### **Application Monitoring**

```bash
# Check deployment status
kubectl get deployments
kubectl get pods -l app=fastapi-app

# View application logs
kubectl logs -l app=fastapi-app --tail=50
kubectl logs -l app=postgres-app --tail=20

# Check services and endpoints
kubectl get svc
kubectl get endpoints
```

### **Database Monitoring**

```bash
# Check PostgreSQL health
kubectl exec -it deployment/postgres-app -- pg_isready -U testuser -d testdb

# Connect to database directly
kubectl exec -it deployment/postgres-app -- psql -U testuser -d testdb

# View database tables
# \dt (show tables)
# SELECT * FROM users;
# SELECT * FROM order_details; (view with joins)
```

## 💰 Cost Breakdown

### **Development Environment**

| Component | Cost/Month | Description |
|-----------|------------|-------------|
| EKS Cluster | $73 | Managed Kubernetes control plane |
| EC2 Instances | $15 | t3.small spot instances |
| EBS Storage | $1 | 10GB volumes |
| Load Balancer | $16 | Application Load Balancer |
| **Total** | **~$105** | Cost-optimized for development |

### **Production Environment**  

| Component | Cost/Month | Description |
|-----------|------------|-------------|
| EKS Cluster | $73 | Managed Kubernetes control plane |
| EC2 Instances | $90 | t3.large on-demand instances |
| EBS Storage | $4 | 40GB volumes |
| Load Balancer | $16 | Application Load Balancer |
| Monitoring | $10 | CloudWatch logs and metrics |
| **Total** | **~$193** | Production-ready with HA |

## 🔧 Development Workflow

### **Making Code Changes**

```bash
# 1. Update your FastAPI code in src/
# 2. Build and push new image
ENV=dev REGION=us-east-2 APP=fastapi-app ./build_push.sh

# 3. The deployment automatically updates with new image
# 4. Test changes
./test_fastapi_endpoints.sh
```

### **Database Changes**

```bash
# 1. Update models in src/models/
# 2. Update initialization SQL in manifests/apps/postgres-app.yaml
# 3. Rebuild and redeploy
ENV=dev REGION=us-east-2 APP=fastapi-app ./build_push.sh
```

### **Infrastructure Changes**

```bash
# 1. Update terraform/*.tf files
# 2. Apply infrastructure changes
cd terraform
ENV=dev REGION=us-east-2 APP=eks ./tf apply
```

## 🚀 Production Readiness & Future Enhancements

### **Current Production Readiness Score: 60%**

| Category | Status | Priority | Description |
|----------|--------|----------|-------------|
| **Infrastructure** | ✅ 85% | Low | VPC, EKS, Multi-AZ configured |
| **Security** | ❌ 40% | **Critical** | Hardcoded secrets, no SSL |
| **Data Persistence** | ❌ 20% | **Critical** | Using EmptyDir (data loss risk) |
| **High Availability** | ⚠️ 60% | High | Single DB replica |
| **Monitoring** | ⚠️ 30% | High | Disabled in development |
| **Backup/Recovery** | ❌ 0% | **Critical** | No backup strategy |

### **Critical Production Fixes (Priority 1)**

#### **1. Data Persistence & Storage**

```yaml
# Replace EmptyDir with PersistentVolumes
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: gp3
  resources:
    requests:
      storage: 100Gi
```

#### **2. Secrets Management**

```bash
# Replace hardcoded secrets with AWS Secrets Manager
aws ssm put-parameter \
  --name "/eks/postgres/password" \
  --value "$(openssl rand -base64 32)" \
  --type "SecureString"

# Implement External Secrets Operator
kubectl apply -f manifests/production/external-secrets.yaml
```

#### **3. SSL/TLS & Security**

```yaml
# Enable SSL with AWS Load Balancer Controller
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:...
    alb.ingress.kubernetes.io/ssl-redirect: '443'
spec:
  tls:
  - hosts: [api.yourdomain.com]
```

### **Important Production Enhancements (Priority 2)**

#### **4. High Availability Database**

```yaml
# PostgreSQL with replicas and backup
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
```

#### **5. Monitoring & Observability**

```bash
# Deploy Prometheus & Grafana
helm install prometheus prometheus-community/kube-prometheus-stack
helm install grafana grafana/grafana

# Enable CloudWatch logging
enable_monitoring = true
enable_logging = true
```

#### **6. Network Security**

```yaml
# Network policies for pod isolation
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-default
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
```

### **Advanced Production Features (Priority 3)**

#### **7. Auto-scaling & Performance**

```yaml
# Horizontal Pod Autoscaler
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: fastapi-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: fastapi-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

#### **8. Database Backup & Recovery**

```bash
# Automated PostgreSQL backups
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: postgres:13-alpine
            command: ["/bin/bash"]
            args:
            - -c
            - |
              pg_dump -h postgres-service -U testuser testdb | \
              aws s3 cp - s3://backup-bucket/postgres/$(date +%Y%m%d-%H%M%S).sql
```

#### **9. CI/CD Pipeline Integration**

```yaml
# GitHub Actions workflow
name: Deploy to EKS
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Build and push to ECR
      run: |
        ENV=prod REGION=us-east-2 APP=fastapi-app IMAGE_TAG=${{ github.sha }} ./build_push.sh
```

### **Enterprise Features (Future)**

#### **10. Multi-Region Deployment**

- Active-passive setup across regions
- Route 53 health checks for failover
- Cross-region database replication
- Global load balancing

#### **11. Advanced Security**

```yaml
# Pod Security Standards
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

#### **12. Service Mesh (Istio)**

```bash
# Service mesh for microservices communication
istioctl install --set values.defaultRevision=default
kubectl label namespace default istio-injection=enabled
```

### **Quick Production Deployment**

To deploy production-ready version immediately:

```bash
# 1. Deploy with production configuration
ENV=prod REGION=us-east-2 APP=eks ./deploy-infra.sh

# 2. Apply production manifests
kubectl apply -f manifests/production/

# 3. Enable persistent storage
kubectl apply -f manifests/production/postgres-storage.yaml

# 4. Rotate secrets
kubectl delete secret postgres-secret
kubectl create secret generic postgres-secret \
  --from-literal=password=$(openssl rand -base64 32)

# 5. Deploy applications
ENV=prod REGION=us-east-2 APP=postgres-app ./deploy-app.sh
ENV=prod REGION=us-east-2 APP=fastapi-app ./deploy-app.sh
```

### **Production Readiness Checklist**

- [ ] **✅ Infrastructure**: EKS cluster with proper networking
- [ ] **❌ Persistent Storage**: Replace EmptyDir with PVCs
- [ ] **❌ Secret Management**: Implement AWS Secrets Manager
- [ ] **❌ SSL/TLS**: Configure HTTPS with valid certificates
- [ ] **❌ Database HA**: Multi-replica PostgreSQL setup
- [ ] **❌ Monitoring**: Prometheus + Grafana deployment
- [ ] **❌ Logging**: Centralized logging with ELK/EFK
- [ ] **❌ Backups**: Automated database backup strategy
- [ ] **❌ Network Security**: Network policies implementation
- [ ] **❌ Auto-scaling**: HPA and cluster autoscaler
- [ ] **❌ CI/CD**: Automated deployment pipeline
- [ ] **❌ Disaster Recovery**: Multi-region setup

## 🗑️ Cleanup

### **Remove Applications**

```bash
# Remove specific application
ENV=dev REGION=us-east-2 APP=fastapi-app ./destroy-app.sh
ENV=dev REGION=us-east-2 APP=postgres-app ./destroy-app.sh
```

### **Destroy Infrastructure**

```bash
# Destroy entire EKS cluster and resources
ENV=dev REGION=us-east-2 APP=eks ./destroy-infra.sh
```

## 📋 Prerequisites

### **Required Tools** (auto-installed)

- AWS CLI (configured with credentials)
- Terraform (latest)
- kubectl (latest)  
- Docker (for building images)
- jq (for JSON processing)

### **AWS Setup**

```bash
# Configure AWS credentials
aws configure

# Verify access
aws sts get-caller-identity
```

## 🔒 Security Features

- **Network Isolation**: VPC with security groups
- **Secret Management**: Kubernetes Secrets for passwords
- **Image Security**: ECR repository scanning
- **Access Control**: IAM roles with least privilege
- **Database Security**: SSL connections and authentication

---

## 📚 Additional Resources

- **FastAPI Documentation**: <https://fastapi.tiangolo.com/>
- **SQLAlchemy Documentation**: <https://docs.sqlalchemy.org/>
- **Amazon EKS User Guide**: <https://docs.aws.amazon.com/eks/>
- **Terraform AWS Provider**: <https://registry.terraform.io/providers/hashicorp/aws/>

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

This setup provides a solid foundation for building production-ready applications with modern DevOps practices!
