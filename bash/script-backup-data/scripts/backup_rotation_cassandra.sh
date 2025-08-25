#!/bin/bash
# Daily rotate and remove cassandra backups

set -e

BACKUP_RETAINED_NUM=${BACKUP_RETAINED_NUM:-33}

function log() {
  message=$1
  echo "[$(date +%Y-%m-%dT%H:%M:%S)] $message"
}

function gen_days_in_month() {
  start_day="01"
  end_day=$1
  increment="1"
  num_days=$2
  exclude_days=$3
  mode=${4-"top-down"}

  days_in_month=()

  if [[ $mode == "top-down" ]]; then
    start_day=$1
    end_day="01"
    increment="-1"
  fi

  count=0

  for day in $( seq $start_day $increment $end_day );
  do
    [[ $((10#$day)) -lt $((10)) ]] && day="0$day"
    [[ " ${exclude_days[*]} " =~ " ${day} " ]] && continue;

    [[ $((10#$count)) -ge $((10#$num_days)) ]] && break;
    count=$((count + 1))

    days_in_month+=($day)
  done

  echo ${days_in_month[@]}
}

##
# This function will delete folder/file named with date format "YYYYMMDD" / "YYYY-MM-DD" and follow rules:
  # Data is back up within the last 3 months which consists of 33 data versions
  # The 1st month: 30 daily data versions
  # The 2nd month: 2 weekly versions (the 1st and 15th-day data version of 2nd month)
  # The 3rd month: 1 monthly version (the 1st-day data version in 3rd month)
function delete_by_name() {
  backup_date_format="%Y%m%d"

  current_year=$(date -d 'now' +'%y')
  current_month=$(date -d 'now' +'%m')
  current_day=$(date -d 'now' +%d)

  pre_1_month_year=$(date -d "$(date +%Y-%m-15) -1 month" +'%Y')
  pre_1_month=$(date -d "$(date +%Y-%m-15) -1 month" +'%m')
  pre_1_month_end_date=$(date -d "yesterday $pre_1_month/1 + 1 month" "+%d") # pre_1_month_end_date=$(echo $(cal -d $current_year-$pre_1_month) | tail -c 3)

  pre_2_month_year=$(date -d "$(date +%Y-%m-15) -2 month" +'%Y')
  pre_2_month=$(date -d "$(date +%Y-%m-15) -2 month" +'%m')
  pre_2_month_end_date=$(date -d "yesterday $pre_2_month/1 + 1 month" "+%d")   # pre_2_month_end_date=$(echo $(cal -d $current_year-$pre_2_month) | tail -c 3)

  # current_year="2022"
  # current_month="02"
  # current_day="08"

  # pre_1_month_year="2022"
  # pre_1_month="01"
  # pre_1_month_end_date="31"

  # pre_2_month_year="2021"
  # pre_2_month="12"
  # pre_2_month_end_date="31"

  log "[CURRENT-DATE]: $current_year-$current_month-$current_day"
  log "[PRE-1-MONTH-END-DATE]: $pre_1_month_year-$pre_1_month-$pre_1_month_end_date"
  log "[PRE-2-MONTH-END-DATE]: $pre_2_month_year-$pre_2_month-$pre_2_month_end_date"

  retained_days_in_current_month=($( gen_days_in_month $((10#$current_day - 1)) $((10#$current_day - 1)) ))
  # echo ${retained_days_in_current_month[@]}
  retained_days_in_pre_1_month=($( gen_days_in_month $pre_1_month_end_date $((10#$BACKUP_RETAINED_NUM - ${#retained_days_in_current_month[@]} - 3)) "01 15" ))
  # echo ${retained_days_in_pre_1_month[@]}

  remain_day_num=$((10#$BACKUP_RETAINED_NUM - ${#retained_days_in_current_month[@]} - ${#retained_days_in_pre_1_month[@]} -3))
  retained_days_in_pre_2_month=()
  [[ $((10#$remain_day_num)) -ge $((1)) ]] && retained_days_in_pre_2_month+=("15")
  retained_days_in_pre_2_month+=($( gen_days_in_month $pre_2_month_end_date $((10#$remain_day_num - ${#retained_days_in_pre_2_month[@]})) "01 15" ))
  # echo ${retained_days_in_pre_2_month[@]}

  retained_backups=()

  retained_backups+=($(date -d $(date +$pre_2_month_year-$pre_2_month-01) +$backup_date_format))

  for i in ${retained_days_in_pre_2_month[@]};
  do
    retained_backups+=($(date -d $(date +$pre_2_month_year-$pre_2_month-$i) +$backup_date_format))
  done

  retained_backups+=($(date -d $(date +$pre_1_month_year-$pre_1_month-01) +$backup_date_format))
  retained_backups+=($(date -d $(date +$pre_1_month_year-$pre_1_month-15) +$backup_date_format))

  for i in ${retained_days_in_pre_1_month[@]};
  do
    retained_backups+=($(date -d $(date +$pre_1_month_year-$pre_1_month-$i) +$backup_date_format))
  done

  for i in ${retained_days_in_current_month[@]};
  do
    retained_backups+=($(date -d $(date +$current_year-$current_month-$i) +$backup_date_format))
  done

  log "[RETAINED-BACKUPS]: ${retained_backups[*]}"

  for i in $(medusa list-backups | awk '{print $1}');
  do
    if [[ ! " ${retained_backups[*]} " =~ " ${i} " ]]; then
      medusa delete-backup --backup-name $i
    fi
  done
}

# Cassandra
function rotate_cassandra() {
  log "============= Start Cassandra rotation ============="
  #Validations
  backup_count=$(medusa list-backups | wc -l)
  [[ $((10#$backup_count)) -le $((10#$BACKUP_RETAINED_NUM)) ]] \
    && log "Total backups ($backup_count) is less than or equal $BACKUP_RETAINED_NUM, nothing to delete" \
    && return 0

  delete_by_name
  backup_deleted=$(medusa list-backups | wc -l)
  log "End Cassandra rotation, total backups: $backup_deleted"
}

rotate_cassandra