#!/bin/bash

# python/functions from bluesky-devops/tools/odoo/python git repo
ODOO_TOOLS_PYTHON_DIR=${ODOO_TOOLS_PYTHON_DIR:-'~/.backup/python'}
BACKUP_RETAINED_NUM=${BACKUP_RETAINED_NUM:-30}

cd $ODOO_TOOLS_PYTHON_DIR

# review and edit $ODOO_TOOLS_PYTHON_DIR/.env

# init envs
source $ODOO_TOOLS_PYTHON_DIR/.env

# create odoo backup directory, ex: /mnt/backup/odoo
mkdir -p ${BACKUP_DIR}

# install python modules
python3 -m pip install -U -r $ODOO_TOOLS_PYTHON_DIR/requirements.txt

# create a backup
python3 $ODOO_TOOLS_PYTHON_DIR/functions/backup_db_v2.py -a

# delete old backups
for folder in ${BACKUP_DIR}/*; do
  if [ -d "${folder}" ]; then
    for dir in ${folder}/*; do
      cd $dir
      if [ "${PWD}" == "${dir}" ]; then
        for file in $(ls -t -1 | awk "NR>$BACKUP_RETAINED_NUM"); do
          echo "Delete old backup: " ${file}
          rm -rf "${file}"
        done
      fi
    done
  fi
done