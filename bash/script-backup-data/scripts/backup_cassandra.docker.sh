#! /bin/bash
current_date=$(date +"%Y-%m-%d")

if test -z $CASSANDRA_CONTAINER_NAME
then
  echo "Cassandra container name not found"
  exit 1
fi

if test -z $CASSANDRA_DATA_VOLUME_NAME
then
  echo "Cassandra data volume name not found"
  exit 1
fi

if test -z $CASSANDRA_BACKUP_VOLUME_DIRECTORY
then
  echo "Cassandra backup directory not found"
  exit 1
fi

if test -z $CASSANDRA_JMX_USER
then
  echo "Cassandra JMX user not found"
  exit 1
fi

if test -z $CASSANDRA_JMX_PASSWORD
then
  echo "Cassandra JMX password not found"
  exit 1
fi
  
# echo "Perform Cassandra garbage collecting operation"
# docker exec $CASSANDRA_CONTAINER_NAME nodetool -u $CASSANDRA_JMX_USER -pw $CASSANDRA_JMX_PASSWORD garbagecollect
echo "Perform Cassandra Heap flushing operation"
docker exec $CASSANDRA_CONTAINER_NAME nodetool -u $CASSANDRA_JMX_USER -pw $CASSANDRA_JMX_PASSWORD flush

echo "Removing today previous backups"
rm -rf $CASSANDRA_BACKUP_VOLUME_DIRECTORY/$current_date
echo "Backing up cassandra"
mkdir -p $CASSANDRA_BACKUP_VOLUME_DIRECTORY/$current_date
docker run --rm -v $CASSANDRA_DATA_VOLUME_NAME:/cassandra_data:ro -v $CASSANDRA_BACKUP_VOLUME_DIRECTORY:/cassandra_backup -i debian:10.3 tar -cvf /cassandra_backup/$current_date/$current_date-raw.tar -C /cassandra_data/cassandra ./data
echo "Cassandra data backed up"