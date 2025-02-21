echo "# Database Administrator Assignment

📌 Project Overview

This project involves deploying a PostgreSQL database cluster with a load balancer using Helm Charts in a local Minikube Kubernetes cluster. Additionally, it includes:

Database design with related tables

Data generation (100,000 records using Faker or an equivalent library)

Asynchronous replication from the cluster to a standalone PostgreSQL instance

Automation & scripting

Version control & documentation
🏗️ Solution Architecture



The solution comprises:



Minikube Cluster (local Kubernetes setup)



Helm Chart Deployment for PostgreSQL



Load Balancer to manage database traffic



Database Schema (Two related tables with a foreign key)



Automated Data Insertion (100,000 records)



Async Replication to a standalone PostgreSQL instance📂 Project Structure
├── diagrams/                  # Architecture and design diagrams
├── docs/                      # Documentation files
├── k8s/                       # Kubernetes manifests and Helm charts
├── scripts/                   # Automation scripts
├── sql/                       # Database schema and SQL scripts
├── requirements.txt           # Dependencies
├── deployment-guide.md        # Step-by-step deployment guide
├── Dockerfile                 # Docker setup for PostgreSQL
├── .gitignore                 # Ignoring unnecessary files
└── README.md                  # Project documentation


🚀 Deployment Steps

1️⃣ Prerequisites

Minikube installed

Helm installed

kubectl configured

PostgreSQL client tools

Python & pip (for Faker data generation)

2️⃣ Setup Minikube & Helm Chart

minikube start --cpus=2 --memory=2g --disk-size=20g
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install postgres-cluster bitnami/postgresql

📌 Expected Deliverables

✅ GitHub Repository with all scripts & Helm charts
✅ Minikube Kubernetes Cluster running PostgreSQL
✅ Database Schema with 100,000 records
✅ Load Balancer handling database traffic
✅ Async Replication showing synchronized records
✅ Documentation & Diagrams explaining the architecture