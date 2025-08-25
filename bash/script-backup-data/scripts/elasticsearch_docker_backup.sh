#! /bin/bash

current_date=$(date +"%Y-%m-%d")

if test -z $ELASTICSEARCH_SNAPSHOT_VOLUME_NAME
then
  echo "ELASTICSEARCH data volume name not found"
  exit 1
fi

if test -z $ELASTICSEARCH_BACKUP_VOLUME_DIRECTORY
then
  echo "ELASTICSEARCH backup directory not found"
  exit 1
fi

if test -z $ELASTICSEARCH_HOST
then
  echo "Elasticsearch host not found"
  exit 1
fi

if test -z $ELASTICSEARCH_SNAPSHOT_PREFIX
then
  echo "Elasticsearch snapshot prefix not found"
  exit 1
fi

if test -z $ELASTICSEARCH_CONTAINER_NAME
then
  echo "Elasticsearch container name not found"
  exit 1
fi

echo "Removing today previous backups"
rm -rf $ELASTICSEARCH_BACKUP_VOLUME_DIRECTORY/$current_date
echo "Backing up ELASTICSEARCH"
mkdir -p $ELASTICSEARCH_BACKUP_VOLUME_DIRECTORY/$current_date

echo "Creating snapshot repository"
curl --location --request PUT "$ELASTICSEARCH_HOST/_snapshot/$current_date" \
--header 'Content-Type: application/json' \
--data-raw "{
    \"type\": \"fs\",
    \"settings\": {
        \"compress\": \"true\",
        \"location\": \"/usr/share/elasticsearch/backups/$current_date\"
    }
}"

echo "Creating snapshot"
curl --location --request PUT "$ELASTICSEARCH_HOST/_snapshot/$current_date/$ELASTICSEARCH_SNAPSHOT_PREFIX-$current_date" \
--header 'Content-Type: application/json' \
--data-raw "{
    \"type\": \"fs\",
    \"settings\": {
        \"compress\": \"true\",
        \"location\": \"/usr/share/elasticsearch/backups/$current_date\"
    }
}"

echo "Ensuring snapshotting process is completed"
snapshot_status=""
while [[ $snapshot_status != "SUCCESS" ]]
do
  snapshot_status=$(curl -s -X GET $ELASTICSEARCH_HOST/_snapshot/$current_date/$ELASTICSEARCH_SNAPSHOT_PREFIX-$current_date | jq -r ".snapshots[0].state")
  echo "Snapshotting process has not completed. Retrying in 3 seconds"
  sleep 3
done
echo "Snapshotting process completed"

echo "Moving snapshot"
docker run --rm -v $ELASTICSEARCH_SNAPSHOT_VOLUME_NAME:/elasticsearch_snapshot_data:ro -v $ELASTICSEARCH_BACKUP_VOLUME_DIRECTORY:/elasticsearch_backup -i debian:10.3 tar -cvf /elasticsearch_backup/$current_date/$current_date.tar -C /elasticsearch_snapshot_data ./$current_date
echo "Elasticsearch data has successfully been backed up"

echo "Performing cleanup process"
docker exec -i $ELASTICSEARCH_CONTAINER_NAME rm -rf /usr/share/elasticsearch/backups/$current_date
curl -X DELETE $ELASTICSEARCH_HOST/_snapshot/$current_date
echo "Done cleaning up"