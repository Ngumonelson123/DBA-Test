Introduction
This project involves deploying a PostgreSQL database cluster using Kubernetes and Helm, creating related tables, generating and inserting data, and setting up asynchronous replication to a standalone PostgreSQL instance.

Architecture Overview

Prerequisites
Minikube installed

kubectl installed

Helm installed

Python and pip installed

PostgreSQL client installed

Step-by-Step Deployment Guide
Minikube Setup
Start Minikube:


#minikube start --cpus=2 --memory=2g --disk-size=20g
Check Minikube Status:

#minikube status
PostgreSQL Cluster Deployment
Add Bitnami Repository:

#helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
Deploy PostgreSQL Cluster:

#helm install postgresql-cluster bitnami/postgresql-ha --set postgresqlPassword=YOUR_PASSWORD,postgresqlDatabase=pesalink_db
Verify Deployment:


kubectl get all
Database and Table Creation
Create Tables in PostgreSQL Cluster:

kubectl exec -it postgresql-cluster-postgresql-ha-postgresql-0 -- psql -U postgres -d pesalink_db -c "CREATE TABLE users (id SERIAL PRIMARY KEY, name VARCHAR(255), email VARCHAR(255) UNIQUE, phone VARCHAR(15) UNIQUE);"
Data Generation and Insertion
Generate and Insert Data: Create a generate_data.py script to generate and insert data using the Faker library:

python
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
Run the Data Generation Script: Deploy a Kubernetes Job to run the data generation script:

yaml
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
Apply the Job:

kubectl apply -f generate-data-job.yaml
Standalone PostgreSQL Deployment

#Deploy Standalone PostgreSQL:

helm install standalone-postgresql bitnami/postgresql --set postgresqlPassword=YOUR_PASSWORD,postgresqlDatabase=pesalink_replica_db

#Verify Deployment:

kubectl get all
Asynchronous Replication Setup
Create Replication User:

sh
kubectl exec -it postgresql-cluster-postgresql-ha-postgresql-0 -- psql -U postgres -c "CREATE USER replicator REPLICATION LOGIN ENCRYPTED PASSWORD 'replica_password';"

#Configure Primary Node:

kubectl exec -it postgresql-cluster-postgresql-ha-postgresql-0 -- bash -c "echo \"wal_level = replica\" >> /opt/bitnami/postgresql/conf/postgresql.conf"
kubectl exec -it postgresql-cluster-postgresql-ha-postgresql-0 -- bash -c "echo \"max_wal_senders = 3\" >> /opt/bitnami/postgresql/conf/postgresql.conf"
kubectl exec -it postgresql-cluster-postgresql-ha-postgresql-0 -- bash -c "echo \"wal_keep_segments = 64\" >> /opt/bitnami/postgresql/conf/postgresql.conf"
kubectl exec -it postgresql-cluster-postgresql-ha-postgresql-0 -- bash -c "echo \"host replication replicator standalone-postgresql.default.svc.cluster.local/32 md5\" >> /opt/bitnami/postgresql/conf/pg_hba.conf"
kubectl rollout restart statefulset postgresql-cluster-postgresql-ha-postgresql

#Configure Standalone Instance:


export POSTGRES_PASSWORD=$(kubectl get secret --namespace default standalone-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)
kubectl run standalone-postgresql-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql:17.4.0-debian-12-r1 --env="PGPASSWORD=$POSTGRES_PASSWORD" -- bash -c "\
echo \"standby_mode = 'on'\" >> /opt/bitnami/postgresql/data/postgresql.conf && \
echo \"primary_conninfo = 'host=postgresql-cluster-postgresql-ha-postgresql-0.postgresql-cluster-postgresql-ha-postgresql-headless.default.svc.cluster.local port=5432 user=replicator password=replica_password'\" >> /opt/bitnami/postgresql/data/postgresql.conf && \
pg_ctl reload"
kubectl rollout restart statefulset standalone-postgresql

#Verification
#Verify Data on Primary Database:


kubectl exec -it postgresql-cluster-postgresql-ha-postgresql-0 -- psql -U postgres -d pesalink_db -c "SELECT COUNT(*) FROM users;"

#Verify Data on Standalone Database:

kubectl run standalone-postgresql-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql:17.4.0-debian-12-r1 --env="PGPASSWORD=$POSTGRES_PASSWORD" -- bash -c "psql --host standalone-postgresql -U postgres -d pesalink_db -c 'SELECT COUNT(*) FROM users;'"