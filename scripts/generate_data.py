import psycopg2
import os
from faker import Faker
import random

# PostgreSQL connection details
DB_HOST = "postgresql-cluster-postgresql-ha-pgpool.mynamespace.svc.cluster.local"
DB_PORT = "5432"
DB_NAME = "pesalink_db"
DB_USER = "postgres"

# ✅ Fetch password dynamically from Kubernetes Secret
DB_PASSWORD = os.popen("kubectl get secret my-release-postgresql-ha-postgresql -n mynamespace -o jsonpath='{.data.password}' | base64 --decode").read().strip()

# Initialize Faker
fake = Faker()
fake.unique.clear()
used_phones = set()

try:
    print("🔄 Connecting to PostgreSQL...")
    conn = psycopg2.connect(
        host=DB_HOST, 
        port=DB_PORT, 
        database=DB_NAME, 
        user=DB_USER, 
        password=DB_PASSWORD
    )
    cur = conn.cursor()
    print("✅ Connected to PostgreSQL.")

    # Check existing user count
    cur.execute("SELECT COUNT(*) FROM users;")
    user_count = cur.fetchone()[0]

    if user_count >= 100000:
        print("⚠️ User limit reached. No new users inserted.")
    else:
        remaining_users = 100000 - user_count
        print(f"🔄 Generating {remaining_users} users...")

        user_batch = []
        for _ in range(remaining_users):
            email = fake.unique.email()
            phone = f"254{random.randint(100000000, 999999999)}"
            while phone in used_phones:
                phone = f"254{random.randint(100000000, 999999999)}"
            used_phones.add(phone)
            user_batch.append((fake.name(), email, phone))

        # ✅ Bulk insert data for better performance
        cur.executemany("INSERT INTO users (name, email, phone) VALUES (%s, %s, %s)", user_batch)
        conn.commit()

        print(f"✅ Successfully inserted {remaining_users} users!")

except psycopg2.OperationalError as db_err:
    print(f"❌ Database Connection Error: {db_err}")
except Exception as e:
    print(f"❌ Unexpected Error: {e}")
finally:
    if 'cur' in locals():
        cur.close()
    if 'conn' in locals():
        conn.close()
        print("🔌 PostgreSQL connection closed.")
