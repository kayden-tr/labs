#!/bin/bash

set -e

APP=${APP:-'app'}

NO_COLOR=${NO_COLOR:-'\033[0m'}
INFO_COLOR=${INFO_COLOR:-'\033[1;32m'}
ERROR_COLOR=${ERROR_COLOR:-'\033[1;31m'}
ENABLE_COLOR=${ENABLE_COLOR:-'false'}

LOG_LEVEL=${LOG_LEVEL:-'info'}
ENABLE_LOG_DATE=${ENABLE_LOG_DATE:-'false'}
LOG_DIR=${LOG_DIR:-"./logs/$APP"}
CURRENT_DATE=$(date +%Y-%m-%dT%H:%M:%S)

mkdir -p $LOG_DIR

LOG_FILE=${LOG_FILE}

write_log() {
  if [[ -n $LOG_FILE ]]; then
    echo -e "$1" >> $LOG_FILE
  else
    echo -e "$1"
  fi
}

log() {
  level=$1
  message=$2

  [[ $ENABLE_COLOR == 'true' ]] && COLOR=$INFO_COLOR
  [[ $ENABLE_LOG_DATE == 'true' ]] && log_date="$(date +%Y-%m-%dT%H:%M:%S) "

  if [[ $level == "debug" ]]; then
    [[ $LOG_LEVEL == "debug" ]] && write_log "$log_date$COLOR${level^^}:$NO_COLOR $COLOR$message$NO_COLOR"
  elif [[ $level == "error" ]]; then
    [[ $ENABLE_COLOR == 'true' ]] && COLOR=$ERROR_COLOR
    write_log "$log_date$COLOR${level^^}:$NO_COLOR $COLOR$message$NO_COLOR"
    exit 1
  else
    write_log "$log_date$COLOR${level^^}:$NO_COLOR $COLOR$message$NO_COLOR"
  fi
}
