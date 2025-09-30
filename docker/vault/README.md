# Vault in docker

## How to start vault

```bash
mkdir -p ./backups ./logs ./data

sudo chown -R 100:1000 ./backups ./logs ./data

docker compose up -d

# vault run with uid 100, gid 1000
```

## How to backup vault

```bash
#!/bin/bash

BACKUP_DATE=$(date +%Y-%m-%d)
BACKUP_DIR=/home/ubuntu/.backup/vault
vault login -method=userpass -address=https://vault.atalink.com username=YOUR_VAULT_USERNAME password=YOUR_VAULT_PASSWORD

VAULT_ADDR=https://vault.atalink.com vault operator raft snapshot save $BACKUP_DIR/$BACKUP_DATE.gz

# Keep last 3 backups
for file in $(ls -t -1 $BACKUP_DIR | awk 'NR>3'); do
  echo "Delete old backup: " ${file}
  rm -rf $BACKUP_DIR/$file
done
```

## How to restore vault

```bash
# Restore from Vault UI

# Restore from command line
vault login

vault operator raft snapshot restore YOUR_BACKUP_FILE_PATH

# Restore to another instance
vault operator raft snapshot restore -force YOUR_BACKUP_FILE_PATH

# Unseal => access Vault UI and unseal using your keys 
```
