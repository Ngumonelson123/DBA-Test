#!/bin/bash

# Database connection details
DB_POD="pesalink-db-postgresql-ha-postgresql-0"
DB_NAME="pesalink_db"
STANDBY_DB_POD="standalone-postgres-postgresql-0"

echo "⚠️  WARNING: This script will DELETE ALL data and reset the database."

# Confirm before proceeding
read -p "Are you sure you want to reset the database? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  echo "❌ Database reset cancelled."
  exit 1
fi

echo "🗑  Dropping existing tables..."
kubectl exec -it $DB_POD -- psql -U postgres -d $DB_NAME -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

echo "📜 Recreating database schema..."
kubectl cp sql/schema.sql $DB_POD:/tmp/schema.sql
kubectl exec -it $DB_POD -- psql -U postgres -d $DB_NAME -f /tmp/schema.sql

echo "📥 Seeding initial data (if available)..."
if [ -f "sql/seed-data.sql" ]; then
  kubectl cp sql/seed-data.sql $DB_POD:/tmp/seed-data.sql
  kubectl exec -it $DB_POD -- psql -U postgres -d $DB_NAME -f /tmp/seed-data.sql
  echo "✅ Seed data inserted!"
else
  echo "⚠️ No seed data file found. Skipping..."
fi

echo "🔄 Resetting Standalone PostgreSQL..."
kubectl exec -it $STANDBY_DB_POD -- psql -U postgres -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
kubectl cp sql/schema.sql $STANDBY_DB_POD:/tmp/schema.sql
kubectl exec -it $STANDBY_DB_POD -- psql -U postgres -d $DB_NAME -f /tmp/schema.sql

echo "✅ Database reset completed successfully!"
