#!/bin/bash
set -e

# Run backup on postgres user
# Set PGPASSWORD env

PG_BACKUP_DIR=${PG_BACKUP_DIR:-$HOME/.backup/postgres}
PG_BACKUP_LOG_DIR=${PG_BACKUP_LOG_DIR:-$HOME/.backup/log}
mkdir -p $PG_BACKUP_DIR
mkdir -p $PG_BACKUP_LOG_DIR

BACKUP_DATE=$(date +%Y-%m-%d)

PG_USER=${PG_USER:-"postgres"}
PG_HOST=${PG_HOST:-"localhost"}
PG_PORT=${PG_PORT:-"5432"}
PG_DB=${PG_DB:-"postgres"}
export PGPASSWORD=${PGPASSWORD:-123QWEasd}

PG_BACKUP_FILE=$PG_DB-$BACKUP_DATE.tar
PG_BACKUP_LOG_FILE=$PG_DB-$BACKUP_DATE.log

pg_dump -h $PG_HOST -p $PG_PORT -U $PG_USER -F t -d $PG_DB -f $PG_BACKUP_DIR/$PG_BACKUP_FILE >> $PG_BACKUP_LOG_DIR/$PG_BACKUP_LOG_FILE 2>&1

# delete old backups
find $PG_BACKUP_DIR -mindepth 1 -mtime +2 -delete
find $PG_BACKUP_LOG_DIR -mindepth 1 -mtime +2 -delete

# pg_restore -h 172.16.7.40 -p 5432 --no-owner --role=postgres -U postgres -W -d bluesky -F t postgres-2021-01-11.tar
