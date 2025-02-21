#!/bin/bash

PRIMARY_HOST="pesalink-db-postgresql-ha-pgpool.default.svc.cluster.local"
STANDBY_HOST="standalone-postgres-postgresql.default.svc.cluster.local"
REPL_USER="replicator"
REPL_PASSWORD="replica_password"
REPL_SLOT="pesalink_replication"

echo "🔄 Configuring replication..."

# Create replication user on the primary
kubectl exec -it pesalink-db-postgresql-ha-postgresql-0 -- psql -U postgres -c "DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$REPL_USER') THEN
        CREATE ROLE $REPL_USER WITH REPLICATION LOGIN PASSWORD '$REPL_PASSWORD';
    END IF;
END
\$\$;"

# Allow replication connections in pg_hba.conf
kubectl exec -it pesalink-db-postgresql-ha-postgresql-0 -- bash -c "
echo 'host replication $REPL_USER 0.0.0.0/0 md5' >> /var/lib/postgresql/data/pg_hba.conf"

# Restart PostgreSQL to apply changes
kubectl exec -it pesalink-db-postgresql-ha-postgresql-0 -- psql -U postgres -c "SELECT pg_reload_conf();"

# Create replication slot (for robustness)
kubectl exec -it pesalink-db-postgresql-ha-postgresql-0 -- psql -U postgres -c "SELECT * FROM pg_create_physical_replication_slot('$REPL_SLOT');"

# Stop the standby PostgreSQL server
kubectl exec -it standalone-postgres-postgresql-0 -- bash -c "pg_ctl stop -D /var/lib/postgresql/data -m fast"

# Remove old data from the standby server
kubectl exec -it standalone-postgres-postgresql-0 -- bash -c "rm -rf /var/lib/postgresql/data/*"

# Perform base backup from primary to standby
kubectl exec -it standalone-postgres-postgresql-0 -- bash -c "
PGPASSWORD=$REPL_PASSWORD pg_basebackup -h $PRIMARY_HOST -D /var/lib/postgresql/data -U $REPL_USER -P --wal-method=stream"

# Configure the standby server for replication
kubectl exec -it standalone-postgres-postgresql-0 -- bash -c "
echo 'primary_conninfo = \"host=$PRIMARY_HOST port=5432 user=$REPL_USER password=$REPL_PASSWORD sslmode=prefer\"
promote_trigger_file = \"/tmp/failover.trigger\"' > /var/lib/postgresql/data/postgresql.auto.conf"

# Create `standby.signal` file (PostgreSQL 12+)
kubectl exec -it standalone-postgres-postgresql-0 -- bash -c "touch /var/lib/postgresql/data/standby.signal"

# Start the standby PostgreSQL server
kubectl exec -it standalone-postgres-postgresql-0 -- bash -c "pg_ctl start -D /var/lib/postgresql/data"

echo "✅ Replication setup complete!"
