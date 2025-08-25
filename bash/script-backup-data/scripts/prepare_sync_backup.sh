#!/bin/bash
# Daily sync backup to remote
# Requires libraries: rclone, tar, pigz

set -e

NO_COLOR=${NO_COLOR:-'\033[0m'}
INFO_COLOR=${INFO_COLOR:-'\033[1;32m'}
ERROR_COLOR=${ERROR_COLOR:-'\033[1;31m'}
ENABLE_COLOR=${ENABLE_COLOR:-'false'}
ENABLE_LOG_DATE=${ENABLE_LOG_DATE:-'true'}

BACKUP_DATE=${BACKUP_DATE:-"$(date +%Y-%m-%d -d '-1 day')"}
BACKUP_YEAR=${BACKUP_YEAR:-"$(date +%Y)"}

COMPRESS_CASSANDRA=${COMPRESS_CASSANDRA:-true}
COMPRESS_ELASTICSEARCH=${COMPRESS_ELASTICSEARCH:-true}
COMPRESS_REDIS=${COMPRESS_REDIS:-true}
COMPRESS_SWIFT=${COMPRESS_SWIFT:-true}
COMPRESS_WORDPRESS=${COMPRESS_WORDPRESS:-true}
COMPRESS_BLOG_WORDPRESS=${COMPRESS_BLOG_WORDPRESS:-true}
COMPRESS_HELP_WORDPRESS=${COMPRESS_HELP_WORDPRESS:-true}
COMPRESS_ODOO=${COMPRESS_ODOO:-true}

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
log info "BACKUP_DATE => $BACKUP_DATE"

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

  compress_enabled_env_name="COMPRESS_${platform^^}" # examples: COMPRESS_BLOG-WORDPRESS
  compress_enabled_env_name="${compress_enabled_env_name//-/_}" # examples: COMPRESS_BLOG_WORDPRESS
  compress_enabled="${!compress_enabled_env_name:-true}" # examples: if COMPRESS_BLOG_WORDPRESS=false then compress_enabled=false else compress_enabled=true

  if [[ $compress_enabled == true ]]; then
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

    log info "success compress $platform"
  else
    log info "skip compress $platform"
  fi
done
