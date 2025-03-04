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
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f db-deployment.yaml
kubectl apply -f db-service.yaml
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
  rootpsw: c2VjdXJlcGFzc3dvcmQ= # base64 encoded password
  dbuser: ZWNvbXVzZXI=
  dbpassword: ZWNvbXBhc3N3b3Jk
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
            - name: MARIADB_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-secrets
                  key: rootpsw
            - name: MARIADB_DATABASE
              value: "ecomdb"
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
              value: "db-service"
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
  name: frontend-deployment
spec:
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: frontend-container
          image: my-frontend-image:v1
          env:
            - name: BACKEND_URL
              value: "http://backend-service:5000"
          ports:
            - containerPort: 80
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
  value: "ecomdb"
```
Alternatively, explicitly select the database in PHP:
```php
mysqli_select_db($link, "ecomdb");
```

---

### ❌ 5.3 `mysqli_fetch_assoc() expects parameter 1 to be mysqli_result, bool given`
**Cause**:  
- The SQL query failed.

**Solution**:  
Modify the PHP code to debug errors:
```php
$result = $conn->query("SELECT * FROM products");
if (!$result) {
    die("Query failed: " . $conn->error);
}
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
  mysql -h 127.0.0.1 -P 3307 -u ecomuser -pecompassword ecomdb
  ```

---

## 🎯 7. Next Steps
- Implement **Persistent Volumes** for MariaDB.
- Add **Liveness and Readiness Probes** for better reliability.
- Deploy to a **cloud provider** (AWS, GKE, Azure).

---

**📅 Date:** _(YYYY-MM-DD)_  
**👨‍💻 Author:** _(Your Name)_  
**📌 Project:** _E-commerce Web App on Kubernetes_
