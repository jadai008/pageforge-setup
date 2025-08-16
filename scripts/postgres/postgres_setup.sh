#!/bin/bash
set -e

# --- Usage ---
if [ $# -ne 1 ]; then
  echo "Usage: $0 <postgres_version>"
  exit 1
fi

PG_VERSION=$1

# --- Check environment variables ---
if [ -z "$DAILY_BACKUP_DIR" ]; then
  echo "Error: DAILY_BACKUP_DIR environment variable not set."
  exit 1
fi

if [ -z "$WAL_ARCHIVE_DIR" ]; then
  echo "Error: WAL_ARCHIVE_DIR environment variable not set."
  exit 1
fi

# --- Install PostgreSQL ---
echo "Installing PostgreSQL $PG_VERSION..."
sudo apt-get update
sudo apt-get install -y wget gnupg lsb-release

# Add PostgreSQL repo
wget -qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | \
  sudo tee /etc/apt/sources.list.d/pgdg.list

sudo apt-get update
sudo apt-get install -y postgresql-$PG_VERSION

# --- Configure WAL archiving ---
PG_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
PG_HBA="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"

sudo mkdir -p "$WAL_ARCHIVE_DIR"
sudo chown -R postgres:postgres "$WAL_ARCHIVE_DIR"

sudo sed -i "s/#archive_mode = off/archive_mode = on/" $PG_CONF
sudo sed -i "s|#archive_command = ''|archive_command = 'test ! -f $WAL_ARCHIVE_DIR/%f && cp %p $WAL_ARCHIVE_DIR/%f'|" $PG_CONF
sudo systemctl restart postgresql

# --- Prepare backup directory ---
sudo mkdir -p "$DAILY_BACKUP_DIR"
sudo chown -R postgres:postgres "$DAILY_BACKUP_DIR"

# --- Setup cron jobs ---
CRON_FILE="/tmp/pg_backup_cron"

echo "Creating cron jobs for postgres user..."

# Backup at 2 AM
echo "0 2 * * * pg_basebackup -D $DAILY_BACKUP_DIR/\$(date +\%Y-\%m-\%d) -F tar -z -P -U postgres -X stream -c fast && find $DAILY_BACKUP_DIR -maxdepth 1 -type d -mtime +3 -exec rm -rf {} \;" >> $CRON_FILE

# Cleanup at 3 AM (delete WALs older than 3 days)
echo "0 3 * * * find $WAL_ARCHIVE_DIR -type f -mtime +3 -delete" >> $CRON_FILE

# Install cron
sudo crontab -u postgres $CRON_FILE
rm $CRON_FILE

echo "PostgreSQL $PG_VERSION setup completed."
echo "Daily backups at 2 AM -> $DAILY_BACKUP_DIR"
echo "Old backups cleaned at 3 AM (keep last 3)."
echo "WAL files archived in -> $WAL_ARCHIVE_DIR"
