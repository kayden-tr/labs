#!/bin/bash
set -e
# Purpose: Operate Cassandra
# Author: Phuc Tran

# ---------------------------------------------------------------
# Define Variables
# ---------------------------------------------------------------
DATE=$(date +%Y%m%d)
HOME=$HOME/.backup
LOG=$HOME/logs/snapshot-cassandra-$DATE.log
HOST=`echo $HOSTNAME |awk '{print tolower($0)}'`
SNAPSHOT_NAME=$HOST"_"$DATE
BACKUP_DIR=${BACKUP_DIR:-/mnt/backup/cassandra}
DATA_DIR=${DATA_DIR:-"/var/lib/cassandra"}
JMX_USER=${JMX_USER:-"cassandra"}
JMX_PASSWORD=${JMX_PASSWORD:-"123QWEasd"}
#IP=`ifconfig |grep "inet\ addr:" |grep 172 |sed 's/:/ /g' |awk '{print $3}'`
input=$2

if [ ! -d "$HOME/logs" ]; then
  mkdir -p $HOME/logs
fi

# : get value after -
while getopts ":o:i:n:p:s:k:" op; do
  case "$op" in
    o) type=${OPTARG}
      echo $type
    ;;
    i) ip=${OPTARG}
      echo $ip
    ;;
    n) snapshot_name=${OPTARG}
      echo $snapshot_name
    ;;
    p) path=${OPTARG}
      echo $path
    ;;
    s) schema=${OPTARG}
      echo $schema
    ;;
    k) keyspace=${OPTARG}
      echo $key
    ;;
    *) echo "dump 1" ;;
  esac
done

# ---------------------------------------------------------------
# Snapshot
# ---------------------------------------------------------------
function _t_snapshot() {
  mkdir -p $BACKUP_DIR/$DATE/$HOST
  echo "--------------------- Snapshot Start ---------------------" >> $LOG
    nodetool -u $JMX_USER -pw $JMX_PASSWORD snapshot -t $HOST"_"$DATE >> $LOG
  echo "--------------------- End snapshot ---------------------" >> $LOG
}

function isolate() {
  cd $DATA_DIR
  find . -name "$SNAPSHOT_NAME" -type d > $HOME/logs/folder_list
  while read folder ;
  do
    rsync -aRvu $folder $BACKUP_DIR/$DATE/$HOST
  done < $HOME/logs/folder_list
  rm $HOME/logs/folder_list -rf
}

function process_data() {
  cd $BACKUP_DIR/$DATE/$HOST
  find . -maxdepth 3 -mindepth 3  > $HOME/logs/dir_lvl_three # Get table path
  echo "--------------------- Moving in progress ---------------------"
  while read folder ;
  do
    echo $folder
    mv $folder/snapshots/$SNAPSHOT_NAME/* $folder/ >> $LOG # Move file
  done < $HOME/logs/dir_lvl_three
  echo "--------------------- Moving End  ---------------------"
  rm $HOME/logs/dir_lvl_three -rf
  echo "Remove table path success"

  find . -name "$SNAPSHOT_NAME" -type d -exec rm -rf {}  2> /dev/null || echo "Remove directory snapshot fail"
  echo "Make remove directory snapshot success"
}

function compress() {
  echo "--------------------- Compress in progress ---------------------"
  cd $BACKUP_DIR/$DATE
  tar -c --use-compress-program=pigz -vf $SNAPSHOT_NAME.tar.gz $HOST/ >> $LOG
  echo "--------------------- Compress end ---------------------"
  echo "Remove temp data success"
  rm $HOST/ -rf
}
function delDaily() {
  #IP=$1
  nodetool -u $JMX_USER -pw $JMX_PASSWORD -h $ip -p $PORT clearsnapshot -t $HOST"_"$DATE
  find $BACKUP_DIR -mindepth 1 -mtime +3 -delete
}

# ---------------------------------------------------------------
# Restore process on same cluster
# ---------------------------------------------------------------
function extract() {
  if [ -z "$snapshot_name" ]; then
    echo >&2 "Please input Date you want to restore. ex: 20190228 "
    exit 1
  else
    echo "--------------------- Extracting in progress ---------------------"
      cd $BACKUP_DIR/$snapshot_name
      pigz -dc $HOST"_"$snapshot_name.tar.gz | tar xf -
    echo "--------------------- End extracting  ---------------------"
  fi
}

function _r_rename() {
  HOST_MAIN=$2
  sudo mv $BACKUP_DIR/$HOST_MAIN"_"$DATE.tar.gz $BACKUP_DIR/$HOST"_"$DATE.tar.gz
  extract $1
  sudo mv $BACKUP_DIR/$HOST_MAIN"_"$DATE $BACKUP_DIR/$HOST
}

# ---------------------------------------------------------------
# Load data cassandra
# ---------------------------------------------------------------
function load_data() {
  if [ -z "$ip" ]; then
    echo >&2 " Please input IP Server you want to restore!"
    exit 1
  elif [ -z "$path" ]; then
    echo >&2 "Please input path you store snapshot"
    exit 1
  else
    echo "--------------------- Loading keyspaces in progress ---------------------" >> $LOG
      cd $path # Path/To/Backup
      ## Get table path
      find . -maxdepth 3 -mindepth 3  > $HOME/logs/dir_lvl_three
      cat $HOME/logs/dir_lvl_three > system_keyspace
      ## Don't load system, kong keyspace
      while read key ;
      do
        if [[ $key == *"system"* ]]; then
          echo " Skip $key"
          continue
        elif [[ $key == *"kong"* ]]; then
          echo "Skip $key"
          continue
        else
          sstableloader -d $ip $key >> $LOG
        fi
      done < $HOME/logs/dir_lvl_three
    echo "--------------------- End Loading Keyspaces ---------------------" >> $LOG
    rm $HOME/logs/dir_lvl_three
  fi
}

function load_table() {
  if [ -z "$ip" ]; then
    echo >&2 "Please input IP Server"
    exit 1
  elif [ -z "$path" ]; then
    echo >&2 "Please input path to tables"
    exit 1
  else
    echo $path ## path store snapshot
    sstableloader -d $ip $path
  fi
}

function load_keyspace() {
  if [ -z "$ip" ]; then
    echo >&2 "Please input IP Server"
    exit 1
  elif [ -z "$path" ]; then
    echo >&2 "Please input path to keyspace"
    exit 1
  elif [ -z "$keyspace" ]; then
    echo >&2 "Please input keyspace name"
    exit 1
  else
    echo "--------------------- Loading keyspaces in progress ---------------------" >> $LOG
      cd $path # Path/To/Backup
      find . -maxdepth 3 -mindepth 3 | grep -w "$keyspace" > $HOME/logs/dir_lvl_three
      cat $HOME/logs/dir_lvl_three > system_keyspace
      while read key ;
      do
        if [[ $key == *"system"* ]]; then ## Don't load system keyspace
          echo "Skip loading $key"
          continue
        elif [[ $key == *"kong"* ]]; then ## Don't load kong keyspace
          echo "Skip loading $key"
          continue
        else
          sstableloader -d $ip $key >> $LOG
        fi
      done < $HOME/logs/dir_lvl_three
    echo "--------------------- End Loading Keyspaces  ---------------------" >> $LOG
    rm $HOME/logs/dir_lvl_three
  fi
}

# ---------------------------------------------------------------
# Schema Process
# ---------------------------------------------------------------
function list_keyspace() {
  #IP=$1
  if [ -z "$ip" ]; then
    echo >&2 "Please input IP Server"
    exit 1
  else
    cqlsh $ip -e "DESC KEYSPACES" | awk '{ for (i=1; i<=NF; i++) print $i}' > ./list_keyspace
  fi
}

function export_schema() {
  # IP=$1
  cqlsh $ip -e "DESC SCHEMA" > $BACKUP_DIR/$DATE/$HOST.cql
}
function truncate() {
  cqlsh $ip -e "TRUNCATE $table"
}

function import_schema() {
  if [ -z "$ip" ]; then
    echo >&2 " Please input IP Server "
    exit 1
  elif [ -z "$path" ]; then
    echo >&2 " Please input path to schema! "
    exit 1
  elif [ -z "$schema" ]; then
    echo >&2 " Please input Schema name! "
    exit 1
  else
    echo "--------------------- Importing schema in progress ---------------------"
      cd $path
      cqlsh $ip -e "source '$schema'"
    echo "--------------------- End Importing Schema  ---------------------"
  fi
}

function drop_keyspace() {
  # IP=$1
  if [ -z "$ip" ]; then
    echo >&2 " Please input IP Server "
    exit 1
  else
    cqlsh $ip -e "DESC KEYSPACES" | awk '{ for (i=1; i<=NF; i++) print $i}' > ./list_keyspace
    while read keyspace;
    do
      if [[ $keyspace == *"system"* ]]; then
        echo "skip $keyspace"
        continue
      elif [[ $keyspace == *"kong"* ]]; then
        echo "skip $keyspace"
        continue
      else
        echo "Dropping $keyspace"
        cqlsh $ip -e "drop keyspace $keyspace"
        echo "End dropping $keyspace"
      fi
    done < ./list_keyspace
    rm list_keyspace -rf
  fi
}
function remove_snapshot() {
  while read snapshot;
  do
    nodetool -h $IP -u $JMX_USER -pw $JMX_PASSWORD -p 7199 clearsnapshot -t $snapshot
  done < ./snapshot_list
}
# ---------------------------------------------------------------
# Case
# ---------------------------------------------------------------
case "$type" in
  snapshot)
    _t_snapshot # Snapshot
    isolate
    process_data
    export_schema $ip # Export schema
    compress
    ;;
  load)
    #extract $2
    load_data $ip $path
    ;;
  export)
    export_schema $ip
    ;;
  import)
    import_schema $ip $path $schema
    ;;
  load_one)
    load_table $ip $path
    ;;
  load_keyspace)
    load_keyspace $ip $path $keyspace
    ;;
  list)
    list_keyspace $ip
    ;;
  drop)
    drop_keyspace $2
  ;;
  del_daily)
    delDaily $2
  ;;
  *)
    echo "Usage: `basename $0` - |--- -o snapshot -i IP
                    | -o load -i IP -p /path/to/snapshot
                     \--ex: ./cassandra_process.sh -o load -i 172.69.96.12 -p /mnt/backup/cassandra/20190315/prod-1-cassandra-1
                    |--- -o load_one -i IP -p /path/to/table
                     \--ex: ./cassandra_process.sh -o load_one -i 172.69.96.12 -p ../bluesky_org/org-xxxxxxxxxxxxxx
                    |--- -o load_keyspace -i IP -p /path/to/snapshot -k keyspace
                    |--- -o export -i IP (export schema to file)
                    |--- -o import -i IP -p /path/store/schema -s Schema_name
                     \--ex: ./cassandra_process.sh -o import -i 172.69.96.12 -p /mnt/backup/cassandra/prod-1-cassandra-1 -s db_schema_prod-1-cassandra-1.cql
                    |--- -o list_keyspace -i IP
                    |--- -o drop_keyspace -i IP"
    exit 1
    ;;
esac
exit 0

# NOTE: Truncate 2 tables below when import to different Environment
# truncate bluesky_auth.auth;
# TRUNCATE bluesky_notify.user_notification_tokens ;

## Force update version app
# INSERT INTO atalink_app_management.app_versions (version, "desc", type, features, bugs, limitations, affected_lv, api_version, db_version, minimum_os_version, created_at) VALUES ('000.023.021',null,'android',[],[],[],'appstore','0.5.0','0.1.5','21','2019-05-24T02:03:42.050Z');
# INSERT INTO atalink_app_management.app_versions (version, "desc", type, features, bugs, limitations, affected_lv, api_version, db_version, minimum_os_version, created_at) VALUES ('000.023.021',null,'ios',[],[],[],'appstore','0.5.0','0.1.5','10','2019-05-24T02:03:42.050Z');
