#!/bin/bash

# How to restore wordpress:
## WPvivid Backup > Backup & Restore > Backups:
### Choice the backup item to restore from
### Click Restore

# ##======================= docker restore =============================##
# DOCKER_VOLUME_NAME=$DOCKER_VOLUME_NAME
# docker run --rm -v $DOCKER_VOLUME_NAME:/backup-volume/backup-volume -v /home/ubuntu/backup:/backup busybox tar -zxvf /backup/$DOCKER_VOLUME_NAME.tar.gz -C /backup-volume