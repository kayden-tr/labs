#!/bin/bash

ES_HOST="https://172.16.15.159:9200"
DAYS_TO_KEEP=30
ES_PASSWORD="elastic:123QWEasd\@\?\!"

# Get daye cutoff for deletion
DATE_CUTOFF=$(date -d "-$DAYS_TO_KEEP days" +%Y.%m.%d)

# Get list of indices
curl -u $ES_PASSWORD -s -k "$ES_HOST/_cat/indices?h=index" | while read index; do
    # Check index name format
    if [[ "$index" =~ ([0-9]{4}\.[0-9]{2}\.[0-9]{2}) ]]; then
        index_date="${BASH_REMATCH[1]}"
        if [[ "$index_date" < "$DATE_CUTOFF" ]]; then
            echo "Deleting index: $index"
            curl -u $ES_PASSWORD -s -X DELETE -k "$ES_HOST/$index"
            echo 
        fi
    fi
done