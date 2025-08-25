#!/bin/bash
set -e

NO_COLOR=${NO_COLOR:-'\033[0m'}
INFO_COLOR=${INFO_COLOR:-'\033[1;32m'}
ERROR_COLOR=${ERROR_COLOR:-'\033[1;31m'}
ENABLE_COLOR=${ENABLE_COLOR:-'true'}

ENABLE_LOG_DATE=${ENABLE_LOG_DATE:-'true'}
LOG_DIR=${LOG_DIR:-'./logs/rsync'}
CURRENT_DATE=$(date +%Y-%m-%dT%H:%M:%S)

mkdir -p $LOG_DIR

LOG_FILE=${LOG_FILE:-"$LOG_DIR/rsync.log.$CURRENT_DATE"}

log() {
  level=$1
  message=$2

  [[ $ENABLE_COLOR == 'true' ]] && COLOR=$INFO_COLOR
  [[ $ENABLE_LOG_DATE == 'true' ]] && log_date="$(date +%Y-%m-%dT%H:%M:%S) "

  if [[ $level == "debug" ]]; then
    [[ $LOG_LEVEL == "debug" ]] && echo -e "$log_date$COLOR${level^^}:$NO_COLOR $COLOR$message$NO_COLOR" >> $LOG_FILE
  elif [[ $level == "error" ]]; then
    [[ $ENABLE_COLOR == 'true' ]] && COLOR=$ERROR_COLOR
    echo -e "$log_date$COLOR${level^^}:$NO_COLOR $COLOR$message$NO_COLOR" >> $LOG_FILE
    exit 1
  else
    echo -e "$log_date$COLOR${level^^}:$NO_COLOR $COLOR$message$NO_COLOR" >> $LOG_FILE
  fi
}

src=$SRC
dest=$DEST
EXTRA_ARGS=$EXTRA_ARGS

[[ -n $1 ]] && src=$1
[[ -n $2 ]] && dest=$2

[[ -z $src ]] && log error "src is required, usage: $0 <src> <dest>"
[[ -z $dest ]] && log error "dest is required, usage: $0 <src> <dest>"

log info "start sync from $src -> $dest"
rsync -airv --progress --mkpath $EXTRA_ARGS -e "ssh -o 'StrictHostKeyChecking=no'" $src $dest --log-file=$LOG_FILE
log info "end sync"