#!/bin/bash
set -e

HOST=${1:-localhost}
PORT=${2:-7199}

USER=${USER:-cassandra}
PASSWORD=${PASSWORD:-123QWEasd}

echo "[Starting clear garbage...]"
nodetool -h $HOST -p $PORT -u $USER -pw $PASSWORD status

echo "[Clear snapshot]"
nodetool -h $HOST -p $PORT -u $USER -pw $PASSWORD clearsnapshot

echo "[Clear garbage]"
nodetool -h $HOST -p $PORT -u $USER -pw $PASSWORD flush
nodetool -h $HOST -p $PORT -u $USER -pw $PASSWORD garbagecollect
nodetool -h $HOST -p $PORT -u $USER -pw $PASSWORD cleanup

echo "[Success]"
nodetool -h $HOST -p $PORT -u $USER -pw $PASSWORD status