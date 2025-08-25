#!/bin/bash

# init environment variables
BACKUP_DIR=${BACKUP_DIR:-"/mnt/backup/prometheus"}
DATA_DIR=${DATA_DIR:-"/mnt/log/prod-prometheus/data"}
BACKUP_DATE=${BACKUP_DATE:-"$(date -u +%Y-%m-%d)"}

mkdir -p $BACKUP_DIR

echo "Create prometheus snapshot, BACKUP_DATE => $BACKUP_DATE"
curl -s -X POST http://localhost:9090/api/v1/admin/tsdb/snapshot

echo -e "\nCompress the prometheus snapshot => $BACKUP_DIR/$BACKUP_DATE.tar.gz"
tar -c --use-compress-program=pigz -f $BACKUP_DIR/$BACKUP_DATE.tar.gz -C $DATA_DIR snapshots

echo "Remove the prometheus snapshot => $DATA_DIR/snapshots"
rm -rf $DATA_DIR/snapshots

for file in $(ls -t -1 $BACKUP_DIR | awk 'NR>3'); do
  echo "Delete old backup => $file"
  rm -rf $BACKUP_DIR/$file
done
