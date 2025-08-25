#!/bin/bash

BACKUP_DIR=${BACKUP_DIR:-"/mnt/backup/cassandra-docker"}
DATA_DIR=${DATA_DIR:-"/var/lib/cassandra/data"}

BACKUP_DATE=${BACKUP_DATE:-"$(date -u +%Y-%m-%d)"}

mkdir -p $BACKUP_DIR

nodetool -u $JMX_USER -pw $JMX_PASSWORD flush
nodetool -u $JMX_USER -pw $JMX_PASSWORD clearsnapshot

tar --use-compress-program="pigz -k " -cvf $BACKUP_DIR/$BACKUP_DATE.tar.gz $DATA_DIR
