#!/bin/bash

# Go to wordpress server:
## sudo useradd -m -d /mnt/backup/wordpress wordpress (/mnt/backup/wordpress is Backup NFS Storage)
## sudo chown -R wordpress:wordpress /mnt/backup/wordpress
## sudo passwd wordpress

# Go to wordpress admin website:
## Install WPvivid Backup Plugin (Migration, Backup, Staging – WPvivid Backup and Migration Plugin)
## Config remote storage (sftp) on WPvivid Backup Plugin: WPvidi Backup > Remote Storage > SFTP
### unique-name:
### ip: WORDPRESS_SERVER_IP
### username: WORDPRESS_SERVER_SSH_USERNAME
### password: WORDPRESS_SERVER_SSH_PASSWORD
### port: WORDPRESS_SERVER_SSH_PORT (22)
### dir: WORDPRESS_USER_HOME_DIR

# Schedule daily backup, store backup to remote storage (sftp): WPvidi Backup > Schedule
# Config backups retained in: WPvidi Backup > Settings > General Settings
## DEV, UAT: keep 3 retained backups
## PROD: keep 7 retained backups
# Config compress and archive: WPvidi Backup > Settings > Advanced Settings
## Enable "Compress and Archive", "Compress Files Every": 2000MB (DEV, UAT), 5000MB(PROD)

##======================= docker backup =============================##
# DOCKER_VOLUME_NAME=blog-wordpress_wordpress_data
# docker run --rm -v $DOCKER_VOLUME_NAME:/backup-volume -v /home/ubuntu/backup:/backup busybox tar -zcvf /backup/$DOCKER_VOLUME_NAME.tar.gz /backup-volume