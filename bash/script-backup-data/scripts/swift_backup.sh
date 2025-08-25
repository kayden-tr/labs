#!/bin/bash
# Swift backup
# Requires libraries: getopt, date, python3-swiftclient, tar, pigz, find

ENV_FILE=${ENV_FILE:-'.env'}

if [[ -f $ENV_FILE ]]; then
  echo "INFO: passing environments from $ENV_FILE"
  . $ENV_FILE
else
  echo "INFO: can't stat $ENV_FILE file => skip"
fi

# Common inputs
BACKUP_DATE=${BACKUP_DATE:-"$(date +%Y-%m-%d)"}
BACKUP_DATETIME=${BACKUP_DATETIME:-"$(date +%Y-%m-%dT%H:%M)"}
BACKUP_DIR=${BACKUP_DIR:-"/mnt/backup/swift"}
BACKUP_SCRIPTS_DIR=${BACKUP_SCRIPTS_DIR:-"$HOME/.backup"}
BACKUP_OUTPUT_DIR=$BACKUP_DIR/$BACKUP_DATE

LOG_DIR=${LOG_DIR:-"$BACKUP_SCRIPTS_DIR/logs"}
SWIFT_LOG_FILE=$LOG_DIR/backup-swift-$BACKUP_DATE.log

DOWNLOAD=${DOWNLOAD:-"true"}
COMPRESS=${COMPRESS:-"true"}
#

# Swift inputs
SWIFT_AUTH_URL=${SWIFT_AUTH_URL:-"http://localhost:5000/v3"}
SWIFT_USERNAME=${SWIFT_USERNAME:-''}
SWIFT_PASSWORD=${SWIFT_PASSWORD:-''}
SWIFT_AUTH_VERSION=${SWIFT_AUTH_VERSION:-'3'}
SWIFT_PROJECT_NAME=${SWIFT_PROJECT_NAME:-''}
SWIFT_PROJECT_ID=${SWIFT_PROJECT_ID:-''}
SWIFT_REGION_NAME=${SWIFT_REGION_NAME:-'RegionOne'}
#

mkdir -p $BACKUP_SCRIPTS_DIR
mkdir -p $LOG_DIR

# Usage
usage() {
cat << EOF
Usage: $0 [options]
Swift Backup.

  options:
    -h,   -help,          --help          Display help                      [Optional]

    -d,   -download,      --download      Download all swift objects        [Optional, Default: true]

    -c,   -compress,      --compress      Compress after backup             [Optional, Default: true]

  examples:
    $0
    $0 -h
    $0 -d true -c true
    $0 -d false -c true
    $0 -d true -c false
EOF
}

# Getopts
options=$(getopt -l "help,download:,compress:" -o "hd:c:" -a -n Usage -- "$@")
[[ $? == 1 ]] && exit 1
eval set -- "$options"

while true
do
  case $1 in
    -h|-help|--help)
      usage
      exit 0
      ;;
    -d|-download|--download)
      shift
      DOWNLOAD=$1
      ;;
    -c)
      shift
      COMPRESS=$1
      ;;
    --)
      shift
      break;;
  esac
  shift
done

echo "INFO: swift backup starting" # >> $SWIFT_LOG_FILE

if [[ "$DOWNLOAD" == "true" ]]; then
  /usr/bin/swift --os-auth-url $SWIFT_AUTH_URL \
  --os-username $SWIFT_USERNAME \
  --os-password $SWIFT_PASSWORD \
  --auth-version $SWIFT_AUTH_VERSION \
  --os-project-id $SWIFT_PROJECT_ID \
  --os-region-name $SWIFT_REGION_NAME \
  download \
  --all \
  --output-dir $BACKUP_OUTPUT_DIR # >> $SWIFT_LOG_FILE

  download_status=$?
  [[ $download_status != 0 ]] && echo "WARN: backup download return non-zero code $download_status"
fi

if [[ "$COMPRESS" == "true" ]]; then
  cd $BACKUP_DIR
  tar -c --use-compress-program=pigz -f $BACKUP_DATE.tar.gz --totals $BACKUP_DATE # >> $SWIFT_LOG_FILE
  # tar -zcf $BACKUP_DATE.tar.gz $BACKUP_DATE >> $SWIFT_LOG_FILE
  compress_status=$?
  [[ $compress_status != 0 ]] && echo "WARN: backup compress return non-zero code $compress_status"
  rm -rf $BACKUP_DATE
fi

echo "INFO: swift backup successful" # >> $SWIFT_LOG_FILE

find $LOG_DIR -mindepth 1 -mtime +1 -delete
