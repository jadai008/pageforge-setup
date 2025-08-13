#!/bin/bash
# Enhanced PostgreSQL PITR Recovery Script
# Usage: ./postgres_pitr_auto_recover.sh "2025-08-13 15:42:00"

set -e

# CONFIGURATION
PG_VERSION=17
PGDATA="/var/lib/postgresql/${PG_VERSION}/main"
PGUSER="postgres"
BACKUP_BASE_DIR="/var/lib/postgresql/backups"       # Root folder where daily backups are stored
WAL_ARCHIVE_DIR="/var/lib/postgresql/wal_archive"   # Where WAL files are archived

TARGET_TIME="$1"

if [ -z "$TARGET_TIME" ]; then
    echo "Usage: $0 \"YYYY-MM-DD HH:MM:SS\""
    exit 1
fi

echo "=== PostgreSQL PITR Recovery (Auto) ==="
echo "Target Recovery Time: $TARGET_TIME"

# 1️⃣ Find latest backup before target time
echo "[1/6] Finding latest backup before target time..."
LATEST_BACKUP=$(find "$BACKUP_BASE_DIR" -maxdepth 1 -type d -printf "%T@ %p\n" | sort -n | awk -v target="$(date -d "$TARGET_TIME" +%s)" '$1 <= target { last=$2 } END { print last }')

if [ -z "$LATEST_BACKUP" ]; then
    echo "❌ No backup found before $TARGET_TIME in $BACKUP_BASE_DIR"
    exit 1
fi

echo "✅ Using backup: $LATEST_BACKUP"

# 2️⃣ Stop PostgreSQL
echo "[2/6] Stopping PostgreSQL..."
sudo systemctl stop postgresql

# 3️⃣ Move old data directory
if [ -d "$PGDATA" ]; then
    echo "[3/6] Moving old data directory..."
    sudo mv "$PGDATA" "${PGDATA}_old_$(date +%F_%H%M)"
fi

# 4️⃣ Restore physical backup
echo "[4/6] Restoring backup..."
sudo -u $PGUSER mkdir -p "$PGDATA"

if [ -f "$LATEST_BACKUP/base.tar" ]; then
    echo "Detected tar format backup..."
    sudo -u $PGUSER tar -xvf "$LATEST_BACKUP/base.tar" -C "$PGDATA"
else
    echo "Detected directory format backup..."
    sudo -u $PGUSER cp -R "$LATEST_BACKUP"/* "$PGDATA/"
fi

# 5️⃣ Configure recovery
echo "[5/6] Setting up recovery configuration..."
sudo -u $PGUSER touch "$PGDATA/recovery.signal"

sudo bash -c "cat > $PGDATA/postgresql.auto.conf" <<EOF
restore_command = 'cp ${WAL_ARCHIVE_DIR}/%f %p'
recovery_target_time = '${TARGET_TIME}'
EOF

# 6️⃣ Permissions and restart
echo "[6/6] Setting permissions and starting PostgreSQL..."
sudo chown -R $PGUSER:$PGUSER "$PGDATA"
sudo systemctl start postgresql

echo "=== Recovery started. PostgreSQL will replay WAL logs until $TARGET_TIME ==="
