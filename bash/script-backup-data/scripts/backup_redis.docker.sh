#!/bin/bash

DOCKER_BACKUP_DIR=${DOCKER_BACKUP_DIR:-'/mnt/backup/redis'}
BACKUP_DATE=${BACKUP_DATE:-"$(date -u +%Y-%m-%d)"}
DOCKER_VOLUME_NAME=${DOCKER_VOLUME_NAME:-'redis_data'}

echo "INFO: start backup redis in docker"

mkdir -p $DOCKER_BACKUP_DIR

docker run --rm \
  -v $DOCKER_VOLUME_NAME:/backup-volume \
  -v $DOCKER_BACKUP_DIR:/backup \
  busybox tar -zcvf /backup/$BACKUP_DATE.tar.gz /backup-volume

echo "INFO: success backup redis in docker"

find $DOCKER_BACKUP_DIR -mindepth 1 -mtime +2 -delete

# how to restore
## tar -zxvf $DOCKER_BACKUP_DIR/$BACKUP_DATE.tar.gz
## stop redis
## backup and remove all files in redis data dir
## copy files: appendonly.aof, dum.rdb from extracted backup dir to redis data dir and start redis.