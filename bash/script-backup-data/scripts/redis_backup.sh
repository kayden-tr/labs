#!/bin/bash
set -e

BACKUP_DIR=${BACKUP_DIR:-'/mnt/backup/redis'}
REDIS_DATA_DIR=${REDIS_DATA_DIR:-'/var/lib/redis'}
DAILY_BACKUP_NAME=${DAILY_BACKUP_NAME:-`date +%Y-%m-%d`}

echo "INFO: redis backup start"

mkdir -p $BACKUP_DIR
tar -zcf $BACKUP_DIR/$DAILY_BACKUP_NAME.tar.gz -C $REDIS_DATA_DIR . || echo "INFO: redis files are changed"

echo "INFO: redis backup success"

# how to restore
## tar -zxvf $BACKUP_DIR/$DAILY_BACKUP_NAME.tar.gz
## stop redis
## backup and remove all files in redis data dir
## copy files: appendonly.aof, dum.rdb from extracted backup dir to redis data dir and start redis.