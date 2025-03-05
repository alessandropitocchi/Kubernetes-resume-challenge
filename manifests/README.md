# Web Application Deployment with Kubernetes and Kind

## 📌 Overview
This document describes the deployment of a web application using **Kubernetes** and **Kind (Kubernetes in Docker)**. It includes the setup of **backend, frontend, and database (MariaDB) manifests**, along with testing steps and common errors encountered.

---

## 🚀 1. Setting Up the Local Kubernetes Cluster with Kind

### 1.1 Create the Cluster
To create a **Kind cluster**, run:
```sh
kind create cluster --name my-cluster
```
Verify the cluster:
```sh
kubectl cluster-info --context kind-my-cluster
```

---

## 🛠️ 2. Deploying the Backend, Frontend, and Database

### 2.1 Apply Kubernetes Manifests
```sh
kubectl apply -f backend/
kubectl apply -f frontend/
```
Verify running pods and services:
```sh
kubectl get pods
kubectl get services
```

---

## 🗄️ 3. Database (MariaDB) Configuration

### 3.1 Using ConfigMap for Database Initialization
Create a **ConfigMap** for MariaDB configuration:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: db-configmap
data:
  init-db.sql: |
    CREATE DATABASE IF NOT EXISTS ecomdb;
    CREATE USER IF NOT EXISTS 'ecomuser'@'%' IDENTIFIED BY 'ecompassword';
    GRANT ALL PRIVILEGES ON ecomdb.* TO 'ecomuser'@'%';
    FLUSH PRIVILEGES;
```

### 3.2 Secure Credentials with Kubernetes Secret
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secrets
type: Opaque
data:
  dbhost: ...
  rootpsw: ...
  dbuser: ...
  dbpassword: ...
  dbname: ...
```

### 3.3 Deploy MariaDB with Configuration
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ecomm-db-deploy
spec:
  selector:
    matchLabels:
      app: ecomm-db
  template:
    metadata:
      labels:
        app: ecomm-db
    spec:
      volumes:
        - name: db-init-script
          configMap:
            name: db-configmap
      containers:
        - name: ecomm-db-container
          image: mariadb:latest
          volumeMounts:
            - name: db-init-script
              mountPath: /docker-entrypoint-initdb.d
          env:
            - name: DB_HOST
              valueFrom:
                secretKeyRef:
                  name: db-secrets
                  key: dbhost
            - name: MARIADB_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-secrets
                  key: rootpsw
            - name: MARIADB_DATABASE
              valueFrom:
                secretKeyRef:
                  name: db-secrets
                  key: dbname
            - name: MARIADB_USER
            valueFrom:
              secretKeyRef:
                name: db-secrets
                key: dbuser
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-secrets
                  key: dbpassword
```

---

## 🔄 4. Deploying Backend and Frontend

### 4.1 Backend Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
spec:
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend-container
          image: my-backend-image:v1
          env:
            - name: DB_HOST
              value: "db-svc"
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: db-secrets
                  key: dbuser
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-secrets
                  key: dbpassword
          ports:
            - containerPort: 5000
```

### 4.2 Frontend Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ecomm-web
  labels:
    app: ecomm-web
spec:
  selector:
    matchLabels:
      app: ecomm-web
  template:
    metadata:
      labels:
        app: ecomm-web
    spec:
      containers:
      - name: ecom-web-container
        image: alessandropitocchi/ecommerce-frontend:v1
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
        env:
          - name: DB_HOST
            valueFrom:
              secretKeyRef:
                name: db-secrets
                key: dbhost
          - name: DB_NAME
            valueFrom:
              secretKeyRef:
                name: db-secrets
                key: dbname
          - name: DB_USER
            valueFrom:
              secretKeyRef:
                name: db-secrets
                key: dbuser
          - name: DB_PASSWORD
            valueFrom:
              secretKeyRef:
                name: db-secrets
                key: dbpassword
        ports:
        - containerPort: 80
```

### 4.3 DB storage

- create storageclass - db-sc.yaml
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```
- create pv
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ecomm-pv
spec:
  capacity:
    storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  storageClassName: local-storage
  hostPath:
    path: "/var/mariadb"
```
- create pvc
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: db-pvc-claim
spec:
  storageClassName: local-storage
  resources:
    requests:
      storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
```
- added pvc to db deployment
```yaml
volumes:
  - name: db-persistent-storage
    persistentVolumeClaim:
      claimName: db-pvc-claim

 volumeMounts:
  - name: db-persistent-storage
    mountPath: /var/lib/mysql
```

---

## 🛑 5. Common Errors and Troubleshooting

### ❌ 5.1 `Access denied for user 'ecomuser'@'10.244.0.24' (using password: YES)`
**Cause**:  
- The `ecomuser` database user does not exist or the password is incorrect.

**Solution**:  
Manually create the user inside MariaDB:
```sql
CREATE USER 'ecomuser'@'%' IDENTIFIED BY 'ecompassword';
GRANT ALL PRIVILEGES ON ecomdb.* TO 'ecomuser'@'%';
FLUSH PRIVILEGES;
```
Then restart MariaDB:
```sh
kubectl delete pod -l app=ecomm-db
```

---

### ❌ 5.2 `No database selected`
**Cause**:  
- The `DB_NAME` environment variable is missing.

**Solution**:  
Ensure `MARIADB_DATABASE` is set:
```yaml
- name: MARIADB_DATABASE
    valueFrom:
      secretKeyRef:
        name: db-secrets
        key: dbname
```
Alternatively, explicitly select the database in PHP:
```php
mysqli_select_db($link, "ecomdb");
```
---

## 🔌 6. Local Testing with Port Forwarding
After deployment, use **port forwarding** to access the application locally:

```sh
kubectl port-forward svc/frontend-service 8080:80
kubectl port-forward svc/backend-service 5000:5000
kubectl port-forward svc/db-service 3307:3306
```
- **Frontend:** `http://localhost:8080`
- **Backend:** `http://localhost:5000`
- **Database:** Connect using:
  ```sh
  mysql -h 127.0.0.1 -P 3307 -u ecomuser -p ecompassword ecomdb
  ```

---

## 🎯 7. Next Steps
- Add **Liveness and Readiness Probes** for better reliability.
- Deploy to a **cloud provider** (AWS, GKE, Azure).

---
