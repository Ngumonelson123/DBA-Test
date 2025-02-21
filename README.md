# Senior Database Administrator Assignment

## Introduction
This project involves deploying a PostgreSQL database cluster using Kubernetes and Helm, creating related tables, generating and inserting data, and setting up asynchronous replication to a standalone PostgreSQL instance. The goal is to demonstrate expertise in database administration, Kubernetes, and automation.

---

## Architecture Overview
The architecture consists of:
1. A **PostgreSQL HA (High Availability) Cluster** deployed using Helm.
2. A **standalone PostgreSQL instance** for asynchronous replication.
3. A **data generation script** to populate the database with 100,000 records.
4. Asynchronous replication to ensure data synchronization between the primary cluster and the standalone instance.

![Architecture Diagram](#) 

---

## Prerequisites
Before starting, ensure the following tools are installed:
- **Minikube**: For local Kubernetes cluster setup.
- **kubectl**: Kubernetes command-line tool.
- **Helm**: Package manager for Kubernetes.
- **Python and pip**: For running the data generation script.
- **PostgreSQL client**: For interacting with the database.

---

## Step-by-Step Deployment Guide

### 1. Minikube Setup
Start a local Kubernetes cluster using Minikube:
```bash
minikube start --cpus=2 --memory=2g --disk-size=20g

Verify the Minikube status:

###Verify the Minikube status:

minikube status

###ostgreSQL Cluster Deployment
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

###Deploy the PostgreSQL HA cluster:
helm install postgresql-cluster bitnami/postgresql-ha \
  --set postgresqlPassword=YOUR_PASSWORD,postgresqlDatabase=pesalink_db

  ###Deploy the PostgreSQL HA cluster:

helm install postgresql-cluster bitnami/postgresql-ha \
  --set postgresqlPassword=YOUR_PASSWORD,postgresqlDatabase=pesalink_db

  ###Verify the deployment:

kubectl get all

###Database and Table Creation
kubectl exec -it postgresql-cluster-postgresql-ha-postgresql-0 -- psql -U postgres -d pesalink_db -c "CREATE TABLE users (id SERIAL PRIMARY KEY, name VARCHAR(255), email VARCHAR(255) UNIQUE, phone VARCHAR(15) UNIQUE);"

####Data Generation and Insertion

import psycopg2
from faker import Faker
import random

DB_HOST = "postgresql-cluster-postgresql-ha-postgresql-0.postgresql-cluster-postgresql-ha-postgresql-headless.default.svc.cluster.local"
DB_PORT = "5432"
DB_NAME = "pesalink_db"
DB_USER = "postgres"
DB_PASSWORD = "YOUR_PASSWORD"

fake = Faker()
used_phones = set()

try:
    conn = psycopg2.connect(host=DB_HOST, port=DB_PORT, database=DB_NAME, user=DB_USER, password=DB_PASSWORD)
    cur = conn.cursor()

    cur.execute("SELECT COUNT(*) FROM users;")
    user_count = cur.fetchone()[0]

    if user_count >= 100000:
        print("User limit reached. No new users inserted.")
    else:
        remaining_users = 100000 - user_count
        for _ in range(remaining_users):
            email = fake.unique.email()
            phone = f"254{random.randint(100000000, 999999999)}"
            while phone in used_phones:
                phone = f"254{random.randint(100000000, 999999999)}"
            used_phones.add(phone)
            cur.execute("INSERT INTO users (name, email, phone) VALUES (%s, %s, %s)", (fake.name(), email, phone))
        conn.commit()
except Exception as e:
    print(f"Error: {e}")
finally:
    cur.close()
    conn.close()


###Deploy a Kubernetes Job to run the data generation script:

apiVersion: batch/v1
kind: Job
metadata:
  name: generate-data-job
spec:
  template:
    spec:
      containers:
      - name: data-generator
        image: python:3.12
        command: ["sh", "-c"]
        args:
          - |
            pip install psycopg2 faker &&
            python3 generate_data.py
      restartPolicy: Never


###Apply the Job:

kubectl apply -f generate-data-job.yaml

###Standalone PostgreSQL Deployment

helm install standalone-postgresql bitnami/postgresql \
  --set postgresqlPassword=YOUR_PASSWORD,postgresqlDatabase=pesalink_replica_db


###Verify the deployment:

kubectl get all


#### Asynchronous Replication Setup
###Create Replication User


kubectl exec -it postgresql-cluster-postgresql-ha-postgresql-0 -- psql -U postgres -c "CREATE USER replicator REPLICATION LOGIN ENCRYPTED PASSWORD 'replica_password';"

###Configure Primary Node

kubectl exec -it postgresql-cluster-postgresql-ha-postgresql-0 -- bash -c "echo 'wal_level = replica' >> /opt/bitnami/postgresql/conf/postgresql.conf"
kubectl exec -it postgresql-cluster-postgresql-ha-postgresql-0 -- bash -c "echo 'max_wal_senders = 3' >> /opt/bitnami/postgresql/conf/postgresql.conf"
kubectl exec -it postgresql-cluster-postgresql-ha-postgresql-0 -- bash -c "echo 'wal_keep_segments = 64' >> /opt/bitnami/postgresql/conf/postgresql.conf"
kubectl exec -it postgresql-cluster-postgresql-ha-postgresql-0 -- bash -c "echo 'host replication replicator standalone-postgresql.default.svc.cluster.local/32 md5' >> /opt/bitnami/postgresql/conf/pg_hba.conf"
kubectl rollout restart statefulset postgresql-cluster-postgresql-ha-postgresql

####Configure Standalone Instance

export POSTGRES_PASSWORD=$(kubectl get secret --namespace default standalone-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)
kubectl run standalone-postgresql-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql:17.4.0-debian-12-r1 --env="PGPASSWORD=$POSTGRES_PASSWORD" -- bash -c "
echo 'standby_mode = on' >> /opt/bitnami/postgresql/data/postgresql.conf &&
echo 'primary_conninfo = host=postgresql-cluster-postgresql-ha-postgresql-0.postgresql-cluster-postgresql-ha-postgresql-headless.default.svc.cluster.local port=5432 user=replicator password=replica_password' >> /opt/bitnami/postgresql/data/postgresql.conf &&
pg_ctl reload"
kubectl rollout restart statefulset standalone-postgresql


###Verify Data on Primary Database

kubectl exec -it postgresql-cluster-postgresql-ha-postgresql-0 -- psql -U postgres -d pesalink_db -c "SELECT COUNT(*) FROM users;"


####Verify Data on Standalone Database

kubectl run standalone-postgresql-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql:17.4.0-debian-12-r1 --env="PGPASSWORD=$POSTGRES_PASSWORD" -- bash -c "psql --host standalone-postgresql -U postgres -d pesalink_db -c 'SELECT COUNT(*) FROM users;'"


###To clean up the resources created during this project:

helm uninstall postgresql-cluster
helm uninstall standalone-postgresql
minikube delete



Expected Deliverables
✅ GitHub Repository with all scripts & Helm charts.

✅ Minikube Kubernetes Cluster running PostgreSQL.

✅ Database Schema with 100,000 records.

✅ Load Balancer handling database traffic.

✅ Async Replication showing synchronized records.

✅ Documentation & Diagrams explaining the architecture.