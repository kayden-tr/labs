#!/bin/bash

BACKUP_DIR="/mnt/backup"
SSH_KEY="/home/ubuntu/.ssh/prod-ed25519-default"

echo "---List Cassandra backups---"
sleep 1 
ssh -i $SSH_KEY ubuntu@172.16.17.46 \
    'output=$(medusa list-backups); \
    echo "$output"; echo "Total backup: $(echo "$output" | wc -l)"'
echo

echo "---List ElasticSearch backups---"
sleep 1
ssh -i $SSH_KEY ubuntu@172.16.18.20 \
    "ls -ltrh $BACKUP_DIR/elasticsearch/snapshots/snap-*; \
    echo Total: \$(ls -trh $BACKUP_DIR/elasticsearch/snapshots/snap-* | wc -l)"
echo

echo "---List Redis backups---"
sleep 1 
ssh -i $SSH_KEY ubuntu@172.16.18.20\
    "ls -ltrh $BACKUP_DIR/redis; \
    echo Total: \$(ls $BACKUP_DIR/redis | wc -l)"
echo

echo "---List Swift backups---"
sleep 1 
ssh -i $SSH_KEY ubuntu@172.16.18.20 \
    "ls -ltrh $BACKUP_DIR/swift; \
    echo Total: \$(ls -trh $BACKUP_DIR/swift | wc -l)"
echo

echo "---List Wordpress backups---"
sleep 1
ssh -i $SSH_KEY ubuntu@172.16.18.20 \
    "ls -ltrh $BACKUP_DIR/wordpress; \
    echo Total: \$(ls -trh $BACKUP_DIR/wordpress | wc -l)"
echo

echo "---List Blog-Wordpress backups---"
sleep 1
ssh -i $SSH_KEY ubuntu@172.16.18.20 \
    "ls -ltrh $BACKUP_DIR/blog-wordpress; \
    echo Total: \$(ls -trh $BACKUP_DIR/blog-wordpress | wc -l)"
echo

echo "---List Help-Wordpress backups---"
sleep 1
ssh -i $SSH_KEY ubuntu@172.16.18.20 \
    "ls -ltrh $BACKUP_DIR/help-wordpress; \
    echo Total: \$(ls -trh $BACKUP_DIR/help-wordpress | wc -l)"
echo

echo "---List Logging Daily backups---"
sleep 1
ssh -i $SSH_KEY ubuntu@172.16.18.20 \
    "ls -ltrh $BACKUP_DIR/prod-elasticsearch-log/daily/snap-*; \
    echo Total Daily: \$(ls -trh $BACKUP_DIR/prod-elasticsearch-log/daily/snap-* | wc -l)"
echo

echo "---List Logging Monthly backups---"
sleep 1
ssh -i $SSH_KEY ubuntu@172.16.18.20 \
    "ls -ltrh $BACKUP_DIR/prod-elasticsearch-log/monthly/snap-*; \
    echo Total Monthly: \$(ls -trh $BACKUP_DIR/prod-elasticsearch-log/monthly/snap-* | wc -l)"
echo

echo "---List Monitoring backups---"
sleep 1
ssh -i $SSH_KEY ubuntu@172.16.18.20 \
    "ls -ltrh $BACKUP_DIR/prometheus; \
    echo Total: \$(ls -trh $BACKUP_DIR/prometheus/ | wc -l)"
echo
