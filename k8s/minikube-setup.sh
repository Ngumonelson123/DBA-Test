#!/bin/bash

echo "🚀 Starting Minikube cluster..."
minikube start --memory=8192 --cpus=4 --driver=docker

echo "🔧 Enabling required Minikube add-ons..."
minikube addons enable metrics-server
minikube addons enable ingress

echo "✅ Deploying PostgreSQL HA Cluster..."
helm install pesalink-db -f k8s/helm/values-ha.yaml k8s/helm/
sleep 10

# Check if PostgreSQL HA pods are running
echo "🔄 Checking PostgreSQL HA deployment status..."
kubectl rollout status statefulset/pesalink-db-postgresql-ha

echo "✅ Deploying Standalone PostgreSQL..."
helm install standalone-postgres -f k8s/helm/values-standalone.yaml k8s/helm/
sleep 10  

# Check if Standalone PostgreSQL is running
echo "🔄 Checking Standalone PostgreSQL deployment status..."
kubectl rollout status statefulset/standalone-postgres

echo "✅ Setup Complete!"
