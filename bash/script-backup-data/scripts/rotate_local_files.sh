#!/bin/bash
# Daily rotate backup
# Required libraries: printf, sort, tail, tr, ls, rm, echo, date

set -e

NO_COLOR=${NO_COLOR:-'\033[0m'}
INFO_COLOR=${INFO_COLOR:-'\033[1;32m'}
ERROR_COLOR=${ERROR_COLOR:-'\033[1;31m'}
ENABLE_COLOR=${ENABLE_COLOR:-'false'}
ENABLE_LOG_DATE=${ENABLE_LOG_DATE:-'true'}

log() {
  level=$1
  message=$2

  [[ $ENABLE_COLOR == 'true' ]] && COLOR=$INFO_COLOR
  [[ $ENABLE_LOG_DATE == 'true' ]] && log_date="$(date +%Y-%m-%dT%H:%M:%S) "

  if [[ $level == 'debug' ]]; then
    [[ $LOG_LEVEL == 'debug' ]] && echo -e "$log_date$COLOR${level^^}:$NO_COLOR $COLOR$message$NO_COLOR"
  elif [[ $level == 'error' ]]; then
    [[ $ENABLE_COLOR == 'true' ]] && COLOR=$ERROR_COLOR
    echo -e "$log_date$COLOR${level^^}:$NO_COLOR $COLOR$message$NO_COLOR"
    exit 1
  else
    echo -e "$log_date$COLOR${level^^}:$NO_COLOR $COLOR$message$NO_COLOR"
  fi
}

ROTATE_YEAR=${ROTATE_YEAR:-"$(date +%Y)"}
ROTATE_DIR=${ROTATE_DIR:-"/mnt/backup/$ROTATE_YEAR"}
ROTATE_RETAINED_NUM=${ROTATE_RETAINED_NUM:-30}
platforms=()

for p in $(ls $ROTATE_DIR);
do
  backups=()
  if [[ -d $ROTATE_DIR/$p ]]; then
    platforms+=("$p")

    for b in $(ls $ROTATE_DIR/$p);
    do
      if [[ -f $ROTATE_DIR/$p/$b ]]; then
        backups+=("$b")
      fi
    done

    log info "platform => $p, total_backups: ${#backups[@]}"

    deleted_backups=($(printf '\"%s\"\n' "${backups[@]}" | sort -r | tail -n +$((ROTATE_RETAINED_NUM+1))))

    log info "platform => $p, total_deleted_backups: ${#deleted_backups[@]}"

    for backup in ${deleted_backups[@]};
    do
      backup=$(echo $backup | tr -d '"')
      log info "platform => $p, delete backup: $backup"
      rm $ROTATE_DIR/$p/$backup
    done
  fi
done
