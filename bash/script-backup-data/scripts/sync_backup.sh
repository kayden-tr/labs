#!/bin/bash
# Daily sync backup to remote
# Requires libraries: rclone, tar, pigz

set -e

NO_COLOR=${NO_COLOR:-'\033[0m'}
INFO_COLOR=${INFO_COLOR:-'\033[1;32m'}
ERROR_COLOR=${ERROR_COLOR:-'\033[1;31m'}
ENABLE_COLOR=${ENABLE_COLOR:-'false'}
ENABLE_LOG_DATE=${ENABLE_LOG_DATE:-'true'}

AWS_PROFILE=${AWS_PROFILE:-'s3rw'}

BACKUP_DATE=${BACKUP_DATE:-"$(date +%Y-%m-%d -d '-1 day')"}
BACKUP_YEAR=${BACKUP_YEAR:-"$(date +%Y)"}

SYNC_CASSANDRA=${SYNC_CASSANDRA:-true}
SYNC_ELASTICSEARCH=${SYNC_ELASTICSEARCH:-true}
SYNC_REDIS=${SYNC_REDIS:-true}
SYNC_SWIFT=${SYNC_SWIFT:-true}
SYNC_WORDPRESS=${SYNC_WORDPRESS:-true}
SYNC_BLOG_WORDPRESS=${SYNC_BLOG_WORDPRESS:-true}
SYNC_HELP_WORDPRESS=${SYNC_HELP_WORDPRESS:-true}
SYNC_ODOO=${SYNC_ODOO:-true}

RCLONE_COPY_OPTIONS=${RCLONE_COPY_OPTIONS}
RCLONE_REMOTE_NAME=${RCLONE_REMOTE_NAME:-'viettelidc-backup-server'}
RCLONE_REMOTE_FOLDER_NAME=${RCLONE_REMOTE_FOLDER_NAME:-'/mnt/backup'}

export RCLONE_S3_CHUNK_SIZE=512M
export RCLONE_S3_UPLOAD_CONCURRENCY=2
export RCLONE_TRANSFERS=2
export RCLONE_FAST_LIST=true
export RCLONE_S3_NO_CHECKSUM=true
export RCLONE_S3_NO_CHECK_BUCKET=true

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

BACKUP_DIR=${BACKUP_DIR:-'/mnt/backup'}
UPLOAD_DIR=${UPLOAD_DIR:-'/mnt/upload'}

log info "BACKUP_DIR => $BACKUP_DIR"
log info "UPLOAD_DIR => $UPLOAD_DIR"
log info "BACKUP_YEAR => $BACKUP_YEAR"
log info "BACKUP_DATE => $BACKUP_DATE"
log info "RCLONE_REMOTE_NAME => $RCLONE_REMOTE_NAME"
log info "RCLONE_REMOTE_FOLDER_NAME => $RCLONE_REMOTE_FOLDER_NAME"

cd $BACKUP_DIR

PLATFORMS=(
  'cassandra' 'elasticsearch' 'redis' 'swift'
  'wordpress' 'blog-wordpress' 'help-wordpress' 'odoo'
)

# backup folder of the platform in the backup dir
BACKUP_FOLDERS=(
  'cassandra-medusa' 'elasticsearch' 'redis' 'swift'
  'wordpress' 'blog-wordpress' 'help-wordpress' 'odoo'
)

PATHS_TO_COMPRESS=(
  'echo cassandra-medusa' 'echo elasticsearch' 'echo' "echo -e swift/$BACKUP_DATE"
  "echo -e wordpress/*${BACKUP_DATE}*" "echo -e blog-wordpress/*${BACKUP_DATE}*"
  "echo -e help-wordpress/*${BACKUP_DATE}*" "find odoo -type f -name *${BACKUP_DATE}*"
)

for i in "${!PLATFORMS[@]}";
do
  platform=${PLATFORMS[$i]}
  backup_folder=${BACKUP_FOLDERS[$i]}
  path_to_compress=$(${PATHS_TO_COMPRESS[$i]})
  compress_tmp_dir=$UPLOAD_DIR/$platform

  sync_enabled_env_name="SYNC_${platform^^}" # examples: SYNC_BLOG-WORDPRESS
  sync_enabled_env_name="${sync_enabled_env_name//-/_}" # examples: SYNC_BLOG_WORDPRESS
  sync_enabled="${!sync_enabled_env_name:-true}" # examples: if SYNC_BLOG_WORDPRESS=false then sync_enabled=false else sync_enabled=true

  if [[ $sync_enabled == true ]]; then
    backup="$RCLONE_REMOTE_NAME:$RCLONE_REMOTE_FOLDER_NAME/$BACKUP_YEAR/$backup_folder/$BACKUP_DATE.tar.gz"

    log info "check if backup $backup has existed on the remote"
    check_size=$(rclone ls $backup | awk '{print $1}')

    if [[ $check_size && $check_size -gt 0 ]]; then
      log info "backup $backup has existed => skip sync"
    else
      log info "backup $backup not exists"
      log info "start sync $platform"

      mkdir -p $compress_tmp_dir

      if [[ -f $compress_tmp_dir/$BACKUP_DATE.tar.gz ]]; then
        log info "skip compress $platform, $compress_tmp_dir/$BACKUP_DATE.tar.gz has existed"
      else
        if [[ $path_to_compress == '' ]]; then
          log info "skip compress $platform, using path $backup_folder/$BACKUP_DATE.tar.gz to upload"
          cp $backup_folder/$BACKUP_DATE.tar.gz $compress_tmp_dir/
        else
          log info "path_to_compress => $path_to_compress"
          tar -c --use-compress-program=pigz -f $compress_tmp_dir/$BACKUP_DATE.tar.gz --totals $path_to_compress \
            || log warn 'file changed as we read it'
        fi
      fi

      rclone copy $RCLONE_COPY_OPTIONS $compress_tmp_dir/$BACKUP_DATE.tar.gz \
        $RCLONE_REMOTE_NAME:$RCLONE_REMOTE_FOLDER_NAME/$BACKUP_YEAR/$backup_folder/
      
      log info "end sync $platform"
    fi
  else
    log info "skip sync $platform"
  fi
done
