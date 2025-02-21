README.md
markdown
Copy
Edit
# Pesalink DB Assignment

This project involves setting up a PostgreSQL database within a Kubernetes environment using Helm charts. The goal is to configure a high-availability (HA) PostgreSQL setup and ensure that it is correctly accessible for use by other microservices or applications.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Prerequisites

- **Kubernetes Cluster**: A Kubernetes cluster must be available. Minikube, EKS, GKE, or any other Kubernetes environment can be used.
- **Helm**: Ensure that Helm is installed and configured for deploying charts.
- **Docker**: Docker should be installed for managing containerized applications.
- **Kubectl**: Ensure that `kubectl` is installed and connected to your cluster.

## Installation

1. Clone this repository to your local machine:
   ```bash
   git clone https://github.com/yourusername/pesalink-db-assignment.git
   cd pesalink-db-assignment
Install the PostgreSQL Helm chart:

bash
Copy
Edit
helm install pesalink-db-postgresql bitnami/postgresql-ha
Confirm that the PostgreSQL service is running by checking the pods:

bash
Copy
Edit
kubectl get pods
Once the pods are running, you can access the PostgreSQL pod:

bash
Copy
Edit
kubectl exec -it pesalink-db-postgresql-ha-postgresql-0 -- bash
Log in to PostgreSQL:

bash
Copy
Edit
psql -U postgres
Configuration
The project uses PostgreSQL configured with the following settings:

PostgreSQL Version: 13.x
Database Name: pesalink_db
User: postgres
Password: Password is defined in the Helm chart values and can be updated by modifying the values.yaml file and reinstalling the chart.
Helm Chart Configuration Example:

yaml
Copy
Edit
postgresql:
  password: "yourpassword"
  database: "pesalink_db"
  username: "postgres"
Usage
Once the Helm chart is deployed and the database is running, you can connect to the database from your local machine or other services in the Kubernetes cluster. Use the following credentials:

Username: postgres
Password: Defined in the values.yaml file or Helm release
Example command to connect:

bash
Copy
Edit
psql -U postgres -h pesalink-db-postgresql-ha-postgresql-0 -d pesalink_db
Troubleshooting
Cannot connect to PostgreSQL:
Ensure that PostgreSQL is running by checking the pod status:
bash
Copy
Edit
kubectl get pods
If PostgreSQL is not running, check the logs for errors:
bash
Copy
Edit
kubectl logs pesalink-db-postgresql-ha-postgresql-0
Database not found:
Confirm that the pesalink_db database exists by logging in with the psql command and listing available databases:
bash
Copy
Edit
\l