#!/bin/bash

# Set database credentials
DB_NAME="pesalink_db"
DB_USER="postgres"
BACKUP_DIR="/var/lib/postgresql/backups"

# Get current date
DATE=$(date +%F-%H%M%S)

# Define backup file name
BACKUP_FILE="$BACKUP_DIR/pesalink_db_backup_$DATE.sql"

echo "🚀 Starting PostgreSQL backup..."

# Ensure backup directory exists
mkdir -p $BACKUP_DIR

# Run pg_dump inside PostgreSQL container
kubectl exec pesalink-db-postgresql-ha-postgresql-0 -- pg_dump -U $DB_USER -d $DB_NAME > $BACKUP_FILE

if [ $? -eq 0 ]; then
    echo "✅ Backup successful: $BACKUP_FILE"
else
    echo "❌ Backup failed!"
    exit 1
fi
