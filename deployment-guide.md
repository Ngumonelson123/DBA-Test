Documentation
Architecture Overview
The architecture is designed to demonstrate a scalable and highly available PostgreSQL deployment using Kubernetes and Helm. It includes:

A PostgreSQL HA Cluster for high availability and load balancing.

A Standalone PostgreSQL Instance for asynchronous replication.

A Data Generation Job to populate the database with test data.

Asynchronous Replication to ensure data consistency across clusters.

Detailed Component Descriptions
1. Minikube Cluster
A local Kubernetes cluster used for development and testing.

Hosts all PostgreSQL components and the data generation job.

2. PostgreSQL HA Cluster
Primary Node: Handles all write operations and replicates data to secondary nodes.

Secondary Nodes: Read-only replicas for high availability.

Pgpool-II: Distributes read queries across secondary nodes and routes write queries to the primary node.

3. Standalone PostgreSQL Instance
A single PostgreSQL instance used as a replica.

Receives data asynchronously from the primary PostgreSQL HA cluster.

4. Data Generation Job
A Kubernetes Job that runs a Python script to generate and insert 100,000 records into the users table.

Uses the Faker library to create realistic test data.

5. Asynchronous Replication
Configured using PostgreSQL's WAL (Write-Ahead Logging) mechanism.

A replication user (replicator) is created to facilitate replication.

How It Works
Deployment:

The PostgreSQL HA cluster and standalone instance are deployed using Helm.

The data generation job is deployed as a Kubernetes Job.

Data Insertion:

The data generation job inserts 100,000 records into the users table in the PostgreSQL HA cluster.

Replication:

Data is asynchronously replicated from the primary PostgreSQL HA cluster to the standalone instance.

Verification:

Data consistency is verified by querying both the primary cluster and the standalone instance.

Tools Used
Minikube: For local Kubernetes cluster setup.

Helm: For deploying PostgreSQL HA and standalone instances.

kubectl: For managing Kubernetes resources.

Python: For the data generation script.

PostgreSQL: As the database engine.