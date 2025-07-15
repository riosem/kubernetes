# EKS Infrastructure Architecture

## Overview

This project implements a **production-ready EKS cluster** with a **FastAPI application using SQLAlchemy** and **PostgreSQL database**. The architecture follows cloud-native best practices with proper separation of concerns, though several critical production enhancements are recommended for full production readiness.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Account                              │
├─────────────────────────────────────────────────────────────────┤
│  Terraform Workspaces (Local State)                            │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                   eks-dev Workspace                        │ │
│  │                                                             │ │
│  │  ┌─────────────────────────────────────────────────────────┐│ │
│  │  │                EKS Cluster                             ││ │
│  │  │  ┌─────────────────┐    ┌─────────────────────────────┐││ │
│  │  │  │   FastAPI App   │    │      PostgreSQL DB         │││ │
│  │  │  │                 │    │                             │││ │
│  │  │  │ ┌─────────────┐ │    │ ┌─────────────────────────┐ │││ │
│  │  │  │ │ SQLAlchemy  │◄──────┤ │ PostgreSQL:13-alpine   │ │││ │
│  │  │  │ │ Models      │ │    │ │ Sample Data            │ │││ │
│  │  │  │ │ - User      │ │    │ │ Health Checks          │ │││ │
│  │  │  │ │ - Product   │ │    │ └─────────────────────────┘ │││ │
│  │  │  │ │ - Order     │ │    │                             │││ │
│  │  │  │ └─────────────┘ │    │ ┌─────────────────────────┐ │││ │
│  │  │  │                 │    │ │      pgAdmin Web UI     │ │││ │
│  │  │  │ ┌─────────────┐ │    │ │   (Database Management) │ │││ │
│  │  │  │ │REST API     │ │    │ └─────────────────────────┘ │││ │
│  │  │  │ │/users       │ │    └─────────────────────────────┘││ │
│  │  │  │ │/products    │ │                                   ││ │
│  │  │  │ │/orders      │ │    ┌─────────────────────────────┐││ │
│  │  │  │ │/health      │ │    │        ECR Repository       │││ │
│  │  │  │ │/stats       │ │    │                             │││ │
│  │  │  │ └─────────────┘ │    │  fastapi-app:latest        │││ │
│  │  │  └─────────────────┘    │  (Custom Docker Image)     │││ │
│  │  │                         └─────────────────────────────┘││ │
│  │  └─────────────────────────────────────────────────────────┘│ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Technology Stack

### **Backend Application**

- **FastAPI**: Modern Python web framework with automatic API documentation
- **SQLAlchemy**: ORM for database operations and relationship management
- **PostgreSQL**: Production-grade relational database
- **Pydantic**: Data validation and serialization
- **Uvicorn**: ASGI server for high-performance async handling

### **Infrastructure**

- **Amazon EKS**: Managed Kubernetes service
- **AWS ECR**: Container registry for custom images
- **AWS VPC**: Isolated network environment
- **Application Load Balancer**: External traffic routing
- **Spot Instances**: Cost-optimized compute (dev environment)

### **DevOps**

- **Terraform**: Infrastructure as Code
- **Docker**: Containerization
- **Kubernetes**: Container orchestration
- **kubectl**: Kubernetes management

## Project Structure

```
src/                           # FastAPI Application Source
├── main.py                   # Application entry point
├── database/
│   ├── connection.py         # SQLAlchemy engine & session management
│   └── __init__.py          # Database initialization
├── models/                   # SQLAlchemy ORM Models
│   ├── user.py              # User model with relationships
│   ├── product.py           # Product model
│   ├── order.py             # Order & OrderItem models
│   └── __init__.py
├── schemas/                  # Pydantic schemas for API validation
│   ├── user.py              # User request/response schemas
│   └── __init__.py
├── routers/                  # FastAPI route modules
│   ├── users.py             # User CRUD operations
│   ├── products.py          # Product operations  
│   ├── orders.py            # Order operations
│   └── __init__.py
├── config/
│   └── settings.py          # Application configuration
├── requirements.txt         # Python dependencies
└── Dockerfile              # Container build instructions

manifests/apps/              # Kubernetes Deployments
├── fastapi-app.yaml        # FastAPI app deployment & service
└── postgres-app.yaml      # PostgreSQL + pgAdmin deployment

terraform/                   # Infrastructure as Code
├── main.tf                 # VPC, subnets, ECR repository
├── eks.tf                  # EKS cluster configuration
├── variables.tf            # Terraform variables
├── outputs.tf              # Infrastructure outputs
├── providers.tf            # AWS provider configuration
└── environments/           # Environment-specific configurations
    ├── dev.tfvars         # Development (cost-optimized)
    └── prod.tfvars        # Production (performance-optimized)
```

## Database Architecture

### **SQLAlchemy Models & Relationships**

```python
# User Model
class User:
    id: int (PK)
    username: str (unique)
    email: str (unique)
    created_at: datetime
    updated_at: datetime
    orders: List[Order]  # One-to-many relationship

# Product Model  
class Product:
    id: int (PK)
    name: str
    description: str
    price: float
    created_at: datetime
    updated_at: datetime
    order_items: List[OrderItem]  # One-to-many relationship

# Order Model
class Order:
    id: int (PK)
    user_id: int (FK → users.id)
    total_amount: float
    status: str
    created_at: datetime
    updated_at: datetime
    user: User  # Many-to-one relationship
    order_items: List[OrderItem]  # One-to-many relationship

# OrderItem Model (Junction Table)
class OrderItem:
    id: int (PK)
    order_id: int (FK → orders.id)
    product_id: int (FK → products.id)
    quantity: int
    unit_price: float
    order: Order  # Many-to-one relationship
    product: Product  # Many-to-one relationship
```

### **Database Features**

- **Automatic table creation** on application startup
- **Sample data initialization** with users, products, and orders
- **Database health checks** in `/health` endpoint
- **Connection pooling** via SQLAlchemy
- **Transaction management** with automatic rollback
- **Relationship loading** with SQLAlchemy ORM

## API Endpoints

### **Core Endpoints**

- `GET /` - Application status and metadata
- `GET /health` - Health check with database connectivity test
- `GET /stats` - Real-time statistics from database

### **User Management**

- `GET /users` - List all users with pagination
- `POST /users` - Create new user with validation
- `GET /users/{id}` - Get specific user by ID
- `PUT /users/{id}` - Update user information
- `DELETE /users/{id}` - Delete user

### **Product Management**

- `GET /products` - List all products
- `POST /products` - Create new product
- `GET /products/{id}` - Get specific product
- `PUT /products/{id}` - Update product
- `DELETE /products/{id}` - Delete product

### **Order Management**

- `GET /orders` - List all orders with relationships
- `POST /orders` - Create new order
- `GET /orders/{id}` - Get specific order with items
- `PUT /orders/{id}` - Update order
- `DELETE /orders/{id}` - Delete order

## Environment Configuration

### **Development Environment** (`dev.tfvars`)

- **Cost-optimized** for learning and testing
- `t3.small` instances with spot pricing (~$15/month)
- Single node with auto-scaling to 2 nodes
- Reduced disk size (10GB minimum)
- Monitoring and logging disabled

### **Production Environment** (`prod.tfvars`)  

- **Performance-optimized** for production workloads
- `t3.large` instances with on-demand pricing
- Multi-node setup (2-10 nodes) for high availability
- Full monitoring and logging enabled
- Enhanced security configurations

## Deployment Strategy

### **Infrastructure-First Approach**

1. **Deploy EKS cluster**: `ENV=dev REGION=us-east-2 APP=eks ./deploy-infra.sh`
2. **Build custom image**: `ENV=dev ./build_push.sh`
3. **Deploy database**: `ENV=dev APP=postgres-app ./deploy-app.sh`
4. **Deploy FastAPI app**: `ENV=dev APP=fastapi-app ./deploy-app.sh`

### **Container Image Strategy**

- **FastAPI**: Custom-built image with application code
- **PostgreSQL**: Official `postgres:13-alpine` image
- **pgAdmin**: Official `dpage/pgadmin4:latest` image

### **Configuration Management**

- **Database credentials**: Kubernetes Secrets
- **Application config**: Environment variables
- **Initialization scripts**: ConfigMaps
- **Infrastructure settings**: Terraform variables

## Production Readiness Assessment

### **Current Status: 60% Production Ready**

| Component | Current State | Production Required | Gap Analysis |
|-----------|---------------|--------------------|--------------|
| **Infrastructure** | ✅ 85% Ready | Multi-AZ EKS, VPC, Security Groups | Minor networking tweaks |
| **Security** | ❌ 40% Ready | SSL, Secrets rotation, WAF | **Critical Gap** |
| **Data Persistence** | ❌ 20% Ready | Persistent volumes, backups | **Critical Gap** |
| **High Availability** | ⚠️ 60% Ready | Database replicas, pod distribution | Important |
| **Monitoring** | ⚠️ 30% Ready | Metrics, logging, alerting | Important |
| **Disaster Recovery** | ❌ 10% Ready | Backup strategy, multi-region | **Critical Gap** |

### **Critical Production Gaps**

#### **1. Data Persistence Risk**

```yaml
# Current (DANGEROUS)
volumes:
  - name: postgres-storage
    emptyDir: {}  # ❌ Data lost on pod restart

# Required for Production
volumes:
  - name: postgres-storage
    persistentVolumeClaim:
      claimName: postgres-pvc
```

#### **2. Security Vulnerabilities**

```yaml
# Current (INSECURE)
data:
  password: cGFzc3dvcmQxMjM=  # ❌ Hardcoded password

# Required for Production
valueFrom:
  secretKeyRef:
    name: postgres-secret-ssm  # ✅ External secret management
    key: password
```

#### **3. Single Points of Failure**

```yaml
# Current (NO FAILOVER)
spec:
  replicas: 1  # ❌ Single database instance

# Required for Production
spec:
  replicas: 3  # ✅ High availability setup
```

## Production Enhancement Roadmap

### **Phase 1: Critical Fixes (Weeks 1-2)**

#### **Data Persistence & Backup**

```yaml
# Persistent storage for database
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

# Automated backup CronJob
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: postgres:13-alpine
            command: ["/bin/bash", "-c"]
            args:
            - |
              pg_dump -h postgres-service -U testuser testdb | \
              aws s3 cp - s3://backup-bucket/postgres/$(date +%Y%m%d-%H%M%S).sql
```

#### **Secrets Management with AWS**

```bash
# Create secrets in AWS Systems Manager
aws ssm put-parameter \
  --name "/eks/postgres/password" \
  --value "$(openssl rand -base64 32)" \
  --type "SecureString"

# Deploy External Secrets Operator
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds/bundle.yaml
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/external-secrets.yaml
```

#### **SSL/TLS Implementation**

```yaml
# AWS Load Balancer Controller with SSL
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: fastapi-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-2:ACCOUNT:certificate/CERT-ID
    alb.ingress.kubernetes.io/ssl-redirect: '443'
spec:
  tls:
  - hosts: [api.yourdomain.com]
  rules:
  - host: api.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: fastapi-service
            port:
              number: 80
```

### **Phase 2: High Availability (Weeks 3-4)**

#### **Database High Availability**

```yaml
# PostgreSQL with multiple replicas
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-app
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  template:
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values: [postgres-app]
              topologyKey: kubernetes.io/hostname
```

#### **Auto-scaling Configuration**

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
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### **Phase 3: Monitoring & Observability (Weeks 5-6)**

#### **Prometheus & Grafana Setup**

```bash
# Install Prometheus stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace

# Custom FastAPI metrics
from prometheus_client import Counter, Histogram, generate_latest
REQUEST_COUNT = Counter('fastapi_requests_total', 'Total requests', ['method', 'endpoint'])
REQUEST_DURATION = Histogram('fastapi_request_duration_seconds', 'Request duration')
```

#### **Centralized Logging**

```yaml
# Fluent Bit for log aggregation
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluent-bit
spec:
  template:
    spec:
      containers:
      - name: fluent-bit
        image: fluent/fluent-bit:latest
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: config
          mountPath: /fluent-bit/etc
```

### **Phase 4: Advanced Security (Weeks 7-8)**

#### **Network Policies**

```yaml
# Deny all traffic by default
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-default
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]

# Allow specific communication
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-fastapi-to-postgres
spec:
  podSelector:
    matchLabels:
      app: fastapi-app
  policyTypes: [Egress]
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: postgres-app
    ports:
    - protocol: TCP
      port: 5432
```

#### **Pod Security Standards**

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### **Phase 5: CI/CD & Automation (Weeks 9-10)**

#### **GitHub Actions Pipeline**

```yaml
# .github/workflows/deploy.yml
name: Deploy to EKS
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-2
    
    - name: Build and push to ECR
      run: |
        ENV=prod REGION=us-east-2 APP=fastapi-app IMAGE_TAG=${{ github.sha }} ./build_push.sh
    
    - name: Deploy to EKS
      run: |
        aws eks update-kubeconfig --region us-east-2 --name ${{ secrets.EKS_CLUSTER_NAME }}
        kubectl set image deployment/fastapi-app fastapi=$ECR_URL:${{ github.sha }}
        kubectl rollout status deployment/fastapi-app
```

## Security Features

### **Current Security Measures**

- VPC with private subnets for database isolation
- Security groups restricting traffic flow
- IAM roles with least privilege access
- ECR repository with vulnerability scanning

### **Enhanced Security Roadmap**

- **Network policies** for pod-to-pod communication control
- **Pod security standards** enforcement
- **External secrets management** with AWS Secrets Manager
- **SSL/TLS termination** with valid certificates
- **Web Application Firewall (WAF)** for DDoS protection
- **Audit logging** for compliance requirements

## Scalability & Performance

### **Horizontal Scaling**

- Multiple FastAPI replicas (configured: 2)
- Auto-scaling node groups (1-10 nodes)
- Load balancing across pods
- Database connection pooling

### **Performance Optimization**

- Resource requests and limits on containers
- Efficient query patterns with SQLAlchemy ORM
- Database indexing on key fields
- Spot instances for cost optimization

### **Future Scaling Enhancements**

- **Read replicas** for database scaling
- **Caching layer** with Redis
- **CDN integration** for static content
- **API rate limiting** and throttling

## Cost Optimization

### **Development Environment**

- **EKS cluster**: ~$73/month (fixed)
- **Compute**: ~$15/month (t3.small spot)
- **Storage**: ~$1/month (10GB EBS)
- **Load balancer**: ~$16/month
- **Total**: ~$105/month

### **Production Environment**  

- **EKS cluster**: ~$73/month (fixed)
- **Compute**: ~$90/month (t3.large on-demand)
- **Storage**: ~$4/month (40GB EBS)
- **Load balancer**: ~$16/month
- **Monitoring**: ~$10/month
- **Total**: ~$193/month

### **Cost Optimization Strategies**

- **Spot instances** for development workloads
- **Reserved instances** for production predictable workloads
- **Right-sizing** based on actual usage metrics
- **Auto-scaling** to match demand patterns

## Disaster Recovery & Business Continuity

### **Current State: Minimal DR**

- Single region deployment
- No automated backups
- Manual recovery procedures

### **Production DR Strategy**

```yaml
# Multi-region setup with automated failover
Primary Region: us-east-2
Secondary Region: us-west-2

# Cross-region replication
- Database: PostgreSQL streaming replication
- Storage: S3 cross-region replication
- DNS: Route 53 health checks with failover
```

### **Backup Strategy**

```bash
# Automated backup schedule
- Database: Daily full backup + continuous WAL archiving
- Application data: Hourly incremental backups
- Infrastructure state: Terraform state backup
- Recovery time objective (RTO): 15 minutes
- Recovery point objective (RPO): 1 hour
```

## Future Enterprise Features

### **Service Mesh Integration**

```bash
# Istio for advanced traffic management
istioctl install --set values.defaultRevision=default
kubectl label namespace default istio-injection=enabled
```

### **Multi-Tenancy Support**

- Namespace isolation per tenant
- Resource quotas and limits
- Network policy segregation
- RBAC for tenant-specific access

### **Advanced Monitoring**

- **Distributed tracing** with Jaeger
- **Custom metrics** for business KPIs
- **Anomaly detection** with machine learning
- **Predictive scaling** based on historical data

## Compliance & Governance

### **Security Compliance**

- **SOC 2 Type II** compliance framework
- **GDPR** data protection measures
- **HIPAA** healthcare data security (if applicable)
- **PCI DSS** payment card data security (if applicable)

### **Operational Governance**

- **Change management** processes
- **Incident response** procedures
- **Security audit** trails
- **Compliance monitoring** dashboards

This architecture provides a solid foundation for production workloads while clearly identifying the critical enhancements needed for full production readiness. The phased approach ensures systematic improvement of security, reliability, and operational excellence.
