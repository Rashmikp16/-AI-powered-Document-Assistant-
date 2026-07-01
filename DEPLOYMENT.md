# RAG Document Assistant - Deployment Guide

## Pre-Deployment Checklist

- [ ] All tests passing
- [ ] Environment variables configured
- [ ] API keys securely stored
- [ ] SSL/TLS certificates ready
- [ ] Database backups configured
- [ ] Monitoring and logging setup
- [ ] Load testing completed
- [ ] Security audit completed

---

## Docker Deployment

### Build Images

```bash
# Build backend image
docker build -f Dockerfile.backend -t rag-assistant-backend:1.0.0 .

# Build frontend image
docker build -f Dockerfile.frontend -t rag-assistant-frontend:1.0.0 .

# Tag for registry (e.g., Docker Hub)
docker tag rag-assistant-backend:1.0.0 yourusername/rag-assistant-backend:1.0.0
docker tag rag-assistant-frontend:1.0.0 yourusername/rag-assistant-frontend:1.0.0

# Push to registry
docker push yourusername/rag-assistant-backend:1.0.0
docker push yourusername/rag-assistant-frontend:1.0.0
```

### Production Docker Compose

```yaml
version: '3.8'

services:
  backend:
    image: yourusername/rag-assistant-backend:1.0.0
    restart: always
    ports:
      - "8000:8000"
    environment:
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - CHROMA_DB_PATH=/data/chroma_db
    volumes:
      - backend_data:/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - rag-network

  frontend:
    image: yourusername/rag-assistant-frontend:1.0.0
    restart: always
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_API_URL=http://your-domain.com/api
    depends_on:
      - backend
    networks:
      - rag-network

  nginx:
    image: nginx:latest
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - backend
      - frontend
    networks:
      - rag-network

volumes:
  backend_data:

networks:
  rag-network:
```

---

## Kubernetes Deployment

### Prerequisites
- Kubernetes cluster (EKS, GKE, AKS, etc.)
- kubectl configured
- Docker images pushed to registry

### Create Namespace
```bash
kubectl create namespace rag-assistant
kubectl config set-context --current --namespace=rag-assistant
```

### Create Secrets
```bash
kubectl create secret generic openai-secret \
  --from-literal=api-key=your-openai-key
```

### Deploy Backend
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rag-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: rag-backend
  template:
    metadata:
      labels:
        app: rag-backend
    spec:
      containers:
      - name: backend
        image: yourusername/rag-assistant-backend:1.0.0
        ports:
        - containerPort: 8000
        env:
        - name: OPENAI_API_KEY
          valueFrom:
            secretKeyRef:
              name: openai-secret
              key: api-key
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: rag-backend
spec:
  selector:
    app: rag-backend
  ports:
  - protocol: TCP
    port: 8000
    targetPort: 8000
  type: ClusterIP
```

### Deploy Frontend
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rag-frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: rag-frontend
  template:
    metadata:
      labels:
        app: rag-frontend
    spec:
      containers:
      - name: frontend
        image: yourusername/rag-assistant-frontend:1.0.0
        ports:
        - containerPort: 3000
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "250m"
---
apiVersion: v1
kind: Service
metadata:
  name: rag-frontend
spec:
  selector:
    app: rag-frontend
  ports:
  - protocol: TCP
    port: 3000
    targetPort: 3000
  type: ClusterIP
```

### Deploy Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rag-ingress
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - your-domain.com
    secretName: rag-tls
  rules:
  - host: your-domain.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: rag-backend
            port:
              number: 8000
      - path: /
        pathType: Prefix
        backend:
          service:
            name: rag-frontend
            port:
              number: 3000
```

### Apply Manifests
```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
```

---

## AWS Deployment (ECS Fargate)

### Create Cluster
```bash
aws ecs create-cluster --cluster-name rag-assistant
```

### Create Task Definitions
```bash
# Register backend task
aws ecs register-task-definition \
  --cli-input-json file://backend-task-def.json

# Register frontend task
aws ecs register-task-definition \
  --cli-input-json file://frontend-task-def.json
```

### Create Services
```bash
aws ecs create-service \
  --cluster rag-assistant \
  --service-name rag-backend \
  --task-definition rag-backend:1 \
  --desired-count 2 \
  --launch-type FARGATE
```

---

## CI/CD Pipeline (GitHub Actions)

```yaml
name: Deploy RAG Assistant

on:
  push:
    branches:
      - main
      - production

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Build backend image
        run: |
          docker build -f Dockerfile.backend \
            -t rag-backend:${{ github.sha }} .
      
      - name: Build frontend image
        run: |
          docker build -f Dockerfile.frontend \
            -t rag-frontend:${{ github.sha }} .
      
      - name: Push images
        env:
          REGISTRY_USERNAME: ${{ secrets.DOCKER_USERNAME }}
          REGISTRY_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
        run: |
          echo "$REGISTRY_PASSWORD" | docker login -u "$REGISTRY_USERNAME" --password-stdin
          docker push rag-backend:${{ github.sha }}
          docker push rag-frontend:${{ github.sha }}
      
      - name: Deploy to Kubernetes
        env:
          KUBECONFIG: ${{ secrets.KUBECONFIG }}
        run: |
          kubectl set image deployment/rag-backend \
            backend=rag-backend:${{ github.sha }}
          kubectl set image deployment/rag-frontend \
            frontend=rag-frontend:${{ github.sha }}
```

---

## Monitoring & Logging

### Prometheus Monitoring
```yaml
# Add to docker-compose or kubernetes
prometheus:
  image: prom/prometheus:latest
  ports:
    - "9090:9090"
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml
```

### ELK Stack for Logging
```bash
# Start ELK stack
docker-compose -f elk-docker-compose.yml up -d

# Send logs from application
# Configure logging in app to send to Logstash
```

### Alerts
```yaml
# prometheus-alerts.yml
groups:
  - name: rag-alerts
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        annotations:
          summary: "High error rate detected"
```

---

## Performance Optimization

### Database Optimization
```sql
-- Create indexes for ChromaDB
CREATE INDEX idx_document_id ON chunks(document_id);
CREATE INDEX idx_created_at ON chunks(created_at);
```

### Caching Strategy
```python
# Redis cache for embeddings
redis_client = redis.Redis(host='localhost', port=6379)

# Cache embeddings for 24 hours
redis_client.setex(f"embedding:{text}", 86400, embedding_json)
```

### CDN Setup
- Configure CloudFlare or AWS CloudFront
- Cache static assets
- Gzip compression enabled
- HTTP/2 support

---

## Security Hardening

### SSL/TLS Configuration
```nginx
server {
    listen 443 ssl http2;
    ssl_certificate /etc/ssl/certs/your-cert.crt;
    ssl_certificate_key /etc/ssl/private/your-key.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # Other configuration
}
```

### Rate Limiting
```nginx
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

server {
    location /api/ {
        limit_req zone=api_limit burst=20 nodelay;
    }
}
```

### CORS Configuration
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://your-domain.com"],
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)
```

---

## Backup & Recovery

### Database Backups
```bash
# Backup ChromaDB
tar -czf chroma_backup_$(date +%Y%m%d).tar.gz ./chroma_db

# AWS S3 backup
aws s3 cp chroma_backup.tar.gz s3://your-bucket/backups/
```

### Recovery Procedure
```bash
# Restore from backup
tar -xzf chroma_backup_20240115.tar.gz -C /

# Verify data
python -c "
import chromadb
client = chromadb.PersistentClient(path='./chroma_db')
print(f'Collections: {len(client.list_collections())}')"
```

---

## Post-Deployment Verification

```bash
# Health check
curl https://your-domain.com/health

# API documentation accessible
curl https://your-domain.com/api/docs

# Frontend loads
curl https://your-domain.com

# Test upload
curl -X POST https://your-domain.com/api/documents/upload \
  -F "file=@test.pdf"
```

---

## Rollback Procedure

### Docker Compose Rollback
```bash
# Stop current version
docker-compose down

# Start previous version
docker-compose -f docker-compose.v1.0.1.yml up -d
```

### Kubernetes Rollback
```bash
# Check rollout history
kubectl rollout history deployment/rag-backend

# Rollback to previous version
kubectl rollout undo deployment/rag-backend

# Rollback to specific revision
kubectl rollout undo deployment/rag-backend --to-revision=2
```

---

## Production Configuration

### Environment Variables
```bash
# Production .env
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxx
OPENAI_MODEL=gpt-3.5-turbo
EMBEDDING_MODEL=text-embedding-3-small

# Database
CHROMA_DB_PATH=/mnt/persistent-volume/chroma_db

# Security
ALLOWED_ORIGINS=https://your-domain.com
MAX_FILE_SIZE=104857600  # 100MB
CHUNK_SIZE=1000
CHUNK_OVERLAP=200

# API
DEBUG=false
LOG_LEVEL=INFO
```

---

## Troubleshooting Deployment

### Service Not Starting
```bash
# Check logs
docker logs container_name
kubectl logs deployment/rag-backend

# Check resources
docker stats
kubectl top pods
```

### High Latency
```bash
# Check network
docker network inspect rag-network
kubectl describe svc rag-backend

# Check resource usage
docker stats
kubectl describe nodes
```

### Data Loss
```bash
# Restore from backup
# Follow backup recovery procedure above
```

---

**Last Updated**: 2024-01-15

For additional help, refer to:
- [README.md](README.md)
- [ARCHITECTURE.md](ARCHITECTURE.md)
- [API_DOCUMENTATION.md](API_DOCUMENTATION.md)
