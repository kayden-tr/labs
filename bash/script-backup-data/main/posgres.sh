#!/bin/bash
set -e

usage() {
cat << EOF
Usage: $0 commands|[options]
Backup and restore posgres

  options:
    -h: show help

  commands:
    backup: backup postgres
    restore: restore postgres

  environments:
    BACKUP_DIR: optional, store backup files in this dir
    BACKUP_LOG_DIR: optional, write backup logs to this dir
    PGHOST: required, postgres host
    PGPORT: optional, postgres port, default 5432
    PGUSER: required, postgres user
    PGPASSWORD: required, postgres user password
    PGDATABASE: required, postgres db to backup

  examples:
    $0
    $0 -h
    $0 backup
    $0 restore
EOF
}

validate() {
  log info 'validate required envs'

  [[ -z $PGHOST ]] && log error "PGHOST env is required"
  [[ -z $PGUSER ]] && log error "PGUSER env is required"
  [[ -z $PGPASSWORD ]] && log error "PGPASSWORD env is required"
  [[ -z $PGDATABASE ]] && log error "PGDATABASE env is required"

  log info 'validate postgres client & server version'

  client_version=$(psql -V | awk '{print $3}')

  log info "pg_client_version => $client_version"

  server_version=$(psql -t -c "SELECT version();" | awk '{print $2}')

  log info "pg_server_version => $server_version"

  [[ "$client_version" != "$server_version" ]] && log error "pg_client_version != pg_server_version"
}

backup() {
  log info "start backup postgres db from $PGHOST:$PGPORT/$PGDATABASE to $BACKUP_DIR/$BACKUP_FILE"
  pg_dump -h $PGHOST -p $PGPORT -U $PGUSER -F t -d $PGDATABASE -f $BACKUP_DIR/$BACKUP_FILE
  log info "success backup postgres db from $PGHOST:$PGPORT/$PGDATABASE to $BACKUP_DIR/$BACKUP_FILE"
}

restore() {
  echo "restore"
}

APP="postgres"

BACKUP_DIR=${BACKUP_DIR:-$HOME/.backup/$APP}
BACKUP_LOG_DIR=${BACKUP_LOG_DIR:-$HOME/.backup/logs/$APP}

mkdir -p $BACKUP_DIR
mkdir -p $BACKUP_LOG_DIR

BACKUP_DATE=$(date +%Y-%m-%d)

PGPORT=${PGPORT:-'5432'}

BACKUP_FILE=$PGDATABASE-$BACKUP_DATE.tar
BACKUP_LOG_FILE=$PGDATABASE-$BACKUP_DATE.log

export PGPASSWORD

. ./utils.sh

if [[ '-h --help' =~ $1 ]]; then
 usage
 exit 0
elif [[ 'backup restore' =~ $1 ]]; then
  validate
  $1
else
  log info "unknown command $1, usage: $0 -h"
fi
