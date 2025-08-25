#!/bin/bash
# run with root
set -e

DOCKER_REGISTRY_HOST=${DOCKER_REGISTRY_HOST:-'docker.io'}
KONG_DECK_VERSION=${KONG_DECK_VERSION:-'v1.29.0'}

KONG_BACKUP_ROOT_DIR=${KONG_BACKUP_ROOT_DIR:-'/mnt/backup/kong'}

KONG_ADMIN_ADDR=$KONG_ADMIN_ADDR
KONG_ADMIN_TLS_SKIP_VERIFY=${KONG_ADMIN_TLS_SKIP_VERIFY:-'true'}
KONG_ADMIN_TOKEN=${KONG_ADMIN_TOKEN:-'noauth'}

KONG_BACKUP_DIR=$KONG_BACKUP_ROOT_DIR/$(date +%Y-%m-%d)

mkdir -p $KONG_BACKUP_DIR

chown -R 1000:1000 $KONG_BACKUP_DIR # deckuser in Dockerfile

docker run --rm -it \
  -v $KONG_BACKUP_DIR:/deck \
  $DOCKER_REGISTRY_HOST/kong/deck:$KONG_DECK_VERSION \
  --kong-addr $KONG_ADMIN_ADDR \
  --tls-skip-verify \
  --headers kong-admin-token:$KONG_ADMIN_TOKEN \
  -o /deck/kong.yaml gateway dump --yes

find $KONG_BACKUP_ROOT_DIR -mindepth 1 -mtime +2 -delete