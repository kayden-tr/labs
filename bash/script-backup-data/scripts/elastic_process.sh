#!/bin/bash
set -e
# Purpose: backup/restore elasticsearch
# Author: phucth
# Date: Feb 2019

# ---------------------------------------------------------------
# Define variable
#----------------------------------------------------------------
H_NAME=`echo $HOSTNAME | awk '{print tolower($0)}'`
DATE=$(date +%Y%m%d)
#DATE=20190220
#SERVER=`ifconfig |grep "inet\ addr:" |grep 172 |sed 's/:/ /g' |awk '{print $3}'`
PORT=9200
TEMP_DATA=/mnt/backup/elasticsearch/temp_data
SNAPSHOT_PATH=/mnt/backup/elasticsearch/snapshots
#URL_REQ="http://$SERVER:$PORT/_snapshot/$DATE"

# ---------------------------------------------------------------
# Create Repo storing snapshot
#----------------------------------------------------------------
function _m_make_repo {
  HOST=$1 REPO=$2
  curl -m 30 -XPUT http://$HOST:$PORT/_snapshot/$REPO -H 'Content-Type: application/json' -d '{
     "type": "fs",
     "settings": {
     "location": "'$SNAPSHOT_PATH'/'$REPO'",
     "compress": true
     }
  }'
}
# ---------------------------------------------------------------
# Create snapshot
#----------------------------------------------------------------
function _m_make_snapshot {
  HOST=$1
  curl -m 30 -XPUT http://$HOST:$PORT/_snapshot/daily/$DATE -H 'Content-Type: application/json' -d '{
     "type": "fs",
     "settings": {
     "location": "'$SNAPSHOT_PATH'",
     "compress": true
     }
  }'
}
# ---------------------------------------------------------------
# Delete Index ElasticSearch
#----------------------------------------------------------------
function _d_delete_all_index {
  HOST=$1
  curl -sL http://$HOST:$PORT/_cat/indices | awk '{print $3}' > index.elastic
  while read index ;
  do
  	curl -XDELETE $HOST:$PORT/$index
  done < ./index.elastic
}

# ---------------------------------------------------------------
# Restore snapshot
#----------------------------------------------------------------
function _r_restore() {
  HOST=$1 REPO=$2 NAME=$3
  # put snapshot to es_share repo
  # $1 Input date you want to restore
  if [ -z "$1" ]; then
    echo >&2 "Please input Date you want to restore. ex: 20190228"
    exit 1
  else
    curl -XPOST "http://$HOST:$PORT/_snapshot/$REPO/$NAME/_restore"
  fi
}
function move () {
  # sudo mv $TEMP_DATA/$DATE
  echo "TODO"
}
function _r_restore_diff
{
  HOST=$1 REPO=$2 NAME=$3
  if [ -z "$1" ]; then
    echo >&2 "Please input IP server"
    exit 1
  elif [ -z "$2" ]; then
    echo >&2 "Please input repo store snapshot. ex: 20190228"
    exit 1
  elif [ -z "$3" ]; then
    echo >&2 "Please input snapshot name. ex: prod-1-elastic-1_20190228"
    exit 1
  else
    HOST=$1 REPO=$2 NAME=$3
    curl -XPOST "http://$HOST:$PORT/_snapshot/$REPO/$NAME/_restore"
  fi
}
# ---------------------------------------------------------------
# Restore one index
#----------------------------------------------------------------
function _r_restore_one_index
{
  # $1 Input date you want to restore
  if [ -z "$1" ]; then
    echo >&2 "Please input IP server"
    exit 1
  elif [ -z "$2" ]; then
    echo >&2 "Please input repo store snapshot. ex: 20190228"
    exit 1
  elif [ -z "$3" ]; then
    echo >&2 "Please input name of snapshot. ex: prod-1-elastic-1_20190228"
    exit 1
  elif [ -z "$4" ]; then
    echo >&2 "Please input index you want to restore. ex: org, locations"
    exit 1
  else
    HOST=$1 REPO=$2 NAME=$3 INDEX=$4
    curl -XDELETE $SERVER:$PORT/$INDEX
    echo "$INDEX Status: Deleted"
    sleep 60
    curl -XPOST "http://$HOST:$PORT/_snapshot/$REPO/$NAME/_restore" -H 'Content-Type: application/json' -d '{
     "indices": "'$INDEX'",
     "ignore_unavailable": true,
     "include_global_state": true
    }'
  fi
}

# ---------------------------------------------------------------
# Remove Old Snapshot
#----------------------------------------------------------------
function remove_snapshot() {
  HOST=$1 REPO=$2 NAME=$3
  if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo >&2 "Please check your input!!!"
  else
    echo -e "\n--------------------- Deleting $NAME ---------------------"
    curl -XDELETE "http://$HOST:$PORT/_snapshot/$REPO/$NAME"
    echo -e "\n---------------------$NAME Deleted---------------------"
    echo -e "\n--------------------- Deleting $REPO ---------------------"
    curl -XDELETE "http://$HOST:$PORT/_snapshot/$REPO"
    echo -e "\n--------------------- $REPO Deleted ---------------------"
  fi
}

# ---------------------------------------------------------------
# Do the choice
#----------------------------------------------------------------
HOST=$2 REPO=$3
case "$1" in
  snapshot)
    # _m_make_repo $2 $DATE
    _m_make_snapshot $HOST
  ;;
  make)
    _m_make_repo $HOST $REPO
  ;;
  restore)
    _m_make_repo $2
    _d_delete_all_index $2
    _r_restore $2
  ;;
  restore_diff)
    #_m_make_repo $2
    _d_delete_all_index $2
    _r_restore_diff $2 $3 $4
  ;;
  load_one)
    _r_restore_one_index $2 $3 $4 $5
  ;;
  remove)
    remove_snapshot $2 $3 $4
  ;;

  *)
    echo "Usage: `basename $0` - |--- snapshot + IP Server (take snapshot daily elasticsearch)
                   |--- make + IP Server (make repo daily)
                   |--- restore + IP Server + date (Rollback data to a date pick )
                   |--- restore_diff + IP Server + Repo + snapshot name (restore elastic from other snapshot)
                    \-- ex: ./elastic_process.sh restore_diff 172.69.96.19 20190314 prod-1-elastic-1_20190313
                   |--- load_one + IP Server + Repo + snapshot name + index
                    \-- ex: ./elastic_process.sh load_one 172.69.96.19 20190314 prod-1-elastic-1_20190313 orgs
                   |--- remove Snapshot + IP Server + Repo + snapshot name
                    \-- ex: ./elastic_process.sh load_one 172.69.96.19 20190314 prod-1-elastic-1_20190313"
  ;;
esac