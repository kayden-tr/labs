#!/bin/bash
# Daily rotate s3 backup
# Required libraries: aws, sort, tail, tr, ls, rm, echo, date, awk

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

export AWS_PROFILE=${AWS_PROFILE:-'s3del'}
export AWS_REGION=${AWS_REGION:-'ap-southeast-1'}

BACKUP_YEAR=${BACKUP_YEAR:-"$(date +%Y)"}
S3_ROOT_URL=${S3_ROOT_URL:-"s3://atalinkvn-prod-backup/$BACKUP_YEAR"}
BACKUP_RETAINED_NUM=${BACKUP_RETAINED_NUM:-30}

platforms=$(aws s3 ls $S3_ROOT_URL/ | awk '{print $2}')
for platform in $platforms;
do
  platform=${platform%/}

  aws s3 ls $S3_ROOT_URL/$platform/ > $platform.txt

  total_backups=$(wc -l $platform.txt | awk '{print $1}')
  log info "$platform => total backups: $total_backups"

  if [[ $total_backups -le $BACKUP_RETAINED_NUM ]]; then
    log info "$platform => total_backups <= $BACKUP_RETAINED_NUM, skipping backup rotation"
    continue
  fi

  deleted_backups=($(cat $platform.txt | awk '{print $4}' | sort -r | tail -n +$((BACKUP_RETAINED_NUM+1))))

  log info "$platform => total deleted backups: ${#deleted_backups[@]}"

  for backup in ${deleted_backups[@]};
  do
    log info "$platform => deleting backup: $backup"
    aws s3 rm $S3_ROOT_URL/$platform/$backup
  done
done
