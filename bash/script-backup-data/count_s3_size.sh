#!/bin/bash

export AWS_PROFILE=s3rw

S3_ROOT_URL=${S3_ROOT_URL:-'s3://atalinkvn-prod-backup/2025'}
total_size=0

platforms=$(aws s3 ls $S3_ROOT_URL/ | awk '{print $2}')
for platform in $platforms;
do
  platform=${platform%/}

  if [[ ! -s $platform.txt ]]; then
    aws s3 ls $S3_ROOT_URL/$platform/ > $platform.txt
  fi

  total_backups=$(wc -l $platform.txt | awk '{print $1}')
  echo "$platform => total backups: $total_backups"

  total_p_size=$(cat $platform.txt | awk '{print $3}' | awk '{s+=$1} END {print s}')
  total_p_size_gb=$(echo "scale=2; $total_p_size/1024/1024/1024" | bc)
  echo -e "$platform => total size: $total_p_size_gb GB"

  total_size=$((total_size + total_p_size))
done

total_size_gb=$(echo "scale=2; $total_size/1024/1024/1024" | bc)
echo -e "Total size: $total_size_gb GB"