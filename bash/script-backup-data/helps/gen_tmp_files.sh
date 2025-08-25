#!/bin/bash

TEST_BACKUP_DIR=${TEST_BACKUP_DIR:-test}

rm -rf $TEST_BACKUP_DIR

mkdir -p $TEST_BACKUP_DIR

years=(2025)

gen_backup_files() {
  p_backup_dir=$1
  year=$2
  mon=$3

  mkdir -p $TEST_BACKUP_DIR/$p_backup_dir

  days=$(echo $(cal -d $year-$mon) | tail -c 3)

  for((i=1; i<=$days; i++))
  do
    day=$i
    if [[ $day -lt 10 ]]; then
      day="0$day"
    fi
    backup_tmp_file_suffix=$year-$mon-$day.tar.gz
    backup_tmp_file="$backup_tmp_file_suffix"
    backup_time="0130"
    touch -t $year$mon$day$backup_time $TEST_BACKUP_DIR/$p_backup_dir/$backup_tmp_file
  done
}

gen_backup_folders() {
  p_backup_dir=$1
  year=$2
  mon=$3

  mkdir -p $TEST_BACKUP_DIR/$p_backup_dir

  days=$(echo $(cal -d $year-$mon) | tail -c 3)

  for((i=1; i<=$days; i++))
  do
    day=$i
    if [[ $day -lt 10 ]]; then
      day="0$day"
    fi
    backup_tmp_folder_suffix=$year$mon$day
    backup_tmp_folder="$backup_tmp_folder_suffix"
    mkdir -p $TEST_BACKUP_DIR/$p_backup_dir/$backup_tmp_folder
  done
}

for year in ${years[@]}
do
  for mon in {01..03}
  do
    gen_backup_files cassandra $year $mon
    # gen_backup_files elasticsearch $year $mon
    # gen_backup_files redis $year $mon
    # gen_backup_files swift $year $mon
  done
done
