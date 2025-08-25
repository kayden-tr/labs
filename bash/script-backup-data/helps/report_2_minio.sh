#!/bin/bash

REPORT_DIR=${REPORT_DIR:-out_zip}
OLD_REPORT_DIR=${OLD_REPORT_DIR:-out_zip_old}

files=$(ls -ldG $OLD_REPORT_DIR/* | awk '{print $8}')

for file in ${files[@]}
do
  fullfilename=$(basename -- "$file")
  extension="${fullfilename##*.}"
  filename="${fullfilename%.*}"

  IFS="-" read -ra NAMES <<< "$filename"
  day=${NAMES[0]}
  mon=${NAMES[1]}
  year=$(date -d"${NAMES[2]}-${NAMES[1]}-${NAMES[0]}" +%Y)

  mkdir -p $REPORT_DIR/$year/$mon

  cp $file $REPORT_DIR/$year/$mon/${NAMES[2]}-$mon-$day.zip

  /usr/local/bin/mc cp $REPORT_DIR/$year/$mon/${NAMES[2]}-$mon-$day.zip atalink/hotsea/report/$year/$mon/

  echo "Waiting for server flush"

  sleep 5
done