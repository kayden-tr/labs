#!/bin/bash
# Daily rotate and remove backup files/folders
# Requires libraries: getopt, seq, date, cal, ls, wc, curl, awk

set -e

AVAILABLE_PLATFORMS="cassandra, elasticsearch, redis, swift"
BACKUP_DIR=${BACKUP_DIR:-"/mnt/backup"}
BACKUP_RETAINED_NUM=${BACKUP_RETAINED_NUM:-33}

# Cassandra Inputs
#
# Elasticsearch Inputs
ELASTICSEARCH_IP=$ELASTICSEARCH_IP
ELASTICSEARCH_PORT=${ELASTICSEARCH_PORT:-9200}
#
# Redis Inputs
#
# Swift Inputs
#

# Usage
usage() {
cat << EOF
Usage: $0 [options] [platform_options]
Backup Rotation.

  options:
    -h,   -help,          --help          Display help            [Optional]

    -p,   -platform,      --platform      Choice platform         [Optional, Default: all]
    (Available values: $AVAILABLE_PLATFORMS)

    -n                                    Num of backup retained  [Optional, Default: 33]
    (Override BACKUP_RETAINED_NUM env)


  platform_options:
    -elasticsearch-ip       --elasticsearch-ip        Elasticsearch host      [Required if platform = elasticsearch]
    (Override ELASTICSEARCH_IP env)

    -elasticsearch-port     --elasticsearch-port      Elasticsearch port      [Optional, Default: 9200]
    (Override ELASTICSEARCH_PORT env)


  examples:
    $0
    $0 -h
    $0 -p elasticsearch
EOF
}

# Getopts
options=$(getopt -l "help,platform:,elasticsearch-ip:,elasticsearch-port:" -o "hp:n" -a -n Usage -- "$@")
[[ $? == 1 ]] && exit 1
eval set -- "$options"

while true
do
  case $1 in
    -h|-help|--help)
      usage
      exit 0
      ;;
    -p|-platform|--platform)
      shift
      platform=$1
      ;;
    -n)
      shift
      BACKUP_RETAINED_NUM=$1
      ;;
    -elasticsearch-ip|--elasticsearch-ip)
      shift
      ELASTICSEARCH_IP=$1
      ;;
    -elasticsearch-port|--elasticsearch-port)
      shift
      ELASTICSEARCH_PORT=$1
      ;;
    --)
      shift
      break;;
  esac
  shift
done

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

function delete_by_created_date() { break; }

function remove_es_snapshots() {
  snapshot_name=$1

  # Remove repository
  log "[DELETE-REPOSITORY: $repository]: $(curl -XDELETE http://$ELASTICSEARCH_IP:$ELASTICSEARCH_PORT/_snapshot/daily/$snapshot_name)"
}

##
# This function will delete folder/file named with date format "YYYYMMDD" / "YYYY-MM-DD" and follow rules:
  # Data is back up within the last 3 months which consists of 33 data versions
  # The 1st month: 30 daily data versions
  # The 2nd month: 2 weekly versions (the 1st and 15th-day data version of 2nd month)
  # The 3rd month: 1 monthly version (the 1st-day data version in 3rd month)
function delete_by_name() {
  current_platform=$1
  platform_backup_dir=$2
  backup_type=$3

  backup_file_type="file"
  backup_folder_type="folder"

  folder_date_format="%Y%m%d"
  file_date_format="%Y-%m-%d"

  if [[ $backup_type == $backup_folder_type ]]; then
    backup_date_format=$folder_date_format
  else
    backup_date_format=$file_date_format
  fi

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

  if [[ $current_platform != "elasticsearch" ]]; then
    for i in $(ls $platform_backup_dir);
    do
      i=$(echo $i | awk '{split($0,a,"."); print a[1]}') # Remove file extension
      if [[ ! " ${retained_backups[*]} " =~ " ${i} " ]]; then
        rm -r $platform_backup_dir/$i*
      fi
    done
  else
    list_backups=$(curl -s XGET http://$ELASTICSEARCH_IP:$ELASTICSEARCH_PORT/_snapshot/daily/\* | jq '.snapshots | .[] | .snapshot' | tr -d \")
    for i in $list_backups
    do
      if [[ ! " ${retained_backups[*]} " =~ " ${i} " ]]; then
        remove_es_snapshots $i
      fi
    done
  fi
}

# Cassandra
function rotate_cassandra() {
  log "============= Start Cassandra rotation ============="
  cassandra_backup_dir=$BACKUP_DIR/cassandra
  #Validations
  [[ $((10#$(ls $cassandra_backup_dir | wc -l))) -le $((10#$BACKUP_RETAINED_NUM)) ]] \
    && log "Total file/folder in '$cassandra_backup_dir' is less than or equal $BACKUP_RETAINED_NUM, nothing to delete" \
    && return 0

  delete_by_name "cassandra" $cassandra_backup_dir "folder"
  log "End Cassandra rotation, total backups: $(ls $cassandra_backup_dir | wc -l)"
}

# Elasticsearch
function rotate_elasticsearch() {
  log "============= Start Elasticsearch rotation ============="
  elasticsearch_backup_dir=$BACKUP_DIR/elasticsearch/snapshots
  [[ $((10#$(curl -s XGET http://$ELASTICSEARCH_IP:$ELASTICSEARCH_PORT/_snapshot/daily/\* | jq '.total'))) -le $((10#$BACKUP_RETAINED_NUM)) ]] \
    && log "Total file/folder in '$elasticsearch_backup_dir' is less than or equal $BACKUP_RETAINED_NUM, nothing to delete" \
    && return 0

  [[ -z $ELASTICSEARCH_IP ]] && log "[ERROR] ELASTICSEARCH_IP is required" && return 1

  delete_by_name "elasticsearch" $elasticsearch_backup_dir "folder"
  
  log "End Elasticsearch rotation, total backups: $((10#$(curl -s XGET http://$ELASTICSEARCH_IP:$ELASTICSEARCH_PORT/_snapshot/daily/\* | jq '.total')))"
}

# Redis
function rotate_redis() {
  log "============= Start Redis rotation ============="
  redis_backup_dir=$BACKUP_DIR/redis
  #Validations
  [[ $((10#$(ls $redis_backup_dir | wc -l))) -le $((10#$BACKUP_RETAINED_NUM)) ]] \
    && log "Total file/folder in '$redis_backup_dir' is less than or equal $BACKUP_RETAINED_NUM, nothing to delete" \
    && return 0

  delete_by_name "redis" $redis_backup_dir "file"
  log "End Redis rotation, total backups: $(ls $redis_backup_dir | wc -l)"
}

# Swift
function rotate_swift() {
  log "============= Start Swift rotation ============="
  swift_backup_dir=$BACKUP_DIR/swift
  #Validations
  [[ $((10#$(ls $swift_backup_dir | wc -l))) -le $((10#$BACKUP_RETAINED_NUM)) ]] \
    && log "Total file/folder in '$swift_backup_dir' is less than or equal $BACKUP_RETAINED_NUM, nothing to delete" \
    && return 0

  delete_by_name "swift" $swift_backup_dir "file"
  log "End Swift rotation, total backups: $(ls $swift_backup_dir | wc -l)"
}

if [[ -z $platform ]]; then
  rotate_cassandra
  rotate_elasticsearch
  rotate_redis
  rotate_swift
else
  [[ $platform == "cassandra" ]] && rotate_cassandra
  [[ $platform == "elasticsearch" ]] && rotate_elasticsearch
  [[ $platform == "redis" ]] && rotate_redis
  [[ $platform == "swift" ]] && rotate_swift
fi