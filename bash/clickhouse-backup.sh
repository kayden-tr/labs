#!/bin/bash

CLICKHOUSE_BACKUP_VERSION="v2.6.39"

#Download and install clickhouse-backup
wget https://github.com/Altinity/clickhouse-backup/releases/download/${CLICKHOUSE_BACKUP_VERSION}/clickhouse-backup-linux-amd64.tar.gz; \
tar -xvf clickhouse-backup-linux-amd64.tar.gz; \
sudo mv build/linux/amd64/clickhouse-backup /usr/local/bin/clickhouse-backup; \
sudo chmod +x /usr/local/bin/clickhouse-backup
