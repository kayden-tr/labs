#!/bin/bash

DOCKER_VOLUME_NAME=$DOCKER_VOLUME_NAME
DOCKER_BACKUP_DIR=${DOCKER_BACKUP_DIR:-"$(pwd)/backup"}

DOCKER_VOLUME_NAMES=(
  about-wordpress_mariadb_data
  about-wordpress_wordpress_data
  blog-wordpress_mariadb_data
  blog-wordpress_wordpress_data
  help-wordpress_codeserver_config
  help-wordpress_mariadb_data
  help-wordpress_sftp_data
  help-wordpress_sftp_home
  help-wordpress_wordpress_data
  wordpress_mariadb_data
  wordpress_wordpress_data
)

for DOCKER_VOLUME_NAME in ${DOCKER_VOLUME_NAMES[@]};
do
  docker run --rm -v \
    $DOCKER_VOLUME_NAME:/backup-volume \
    -v $DOCKER_BACKUP_DIR:/backup \
    busybox tar -zcvf /backup/$DOCKER_VOLUME_NAME.tar.gz /backup-volume
done