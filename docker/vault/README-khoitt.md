```bash
## Prepare container Vault

mkdir -p ./backups ./logs ./data ./bin

# vault run with uid 100, gid 1000

sudo chown -R 100:1000 ./backups ./logs ./data ./bin

# Start docker compose

docker compose up -f docker-compose-vault.yml -d

# Access web app for config

http://localhost:8200
Generate root_token and seal_key via website

######################Inside container#############################

# Login

vault login <root_token>

##### Parse unsealed keys

vault operator unseal <keys-base-1>
vault operator unseal <keys-base-2>
vault operator unseal <keys-base-3>

# Enable a Secrets engines kv

write sys/mounts/<mount> type=kv options=version=2

# Add a jenkins username/pass value to jenkins Secrets

vault kv put <mount>/jenkins username=admin password=123

# Create sample admin policy
mkdir /vault/policies
touch /vault/policies/admin-pol.hcl
cat <<EOF > /vault/policies/admin.hcl
path "secret/data/\*" {
    capabilities = ["create", "read", "update", "delete", "list"]
}
EOF

# Create sample dev policy
touch /vault/policies/dev-pol.hcl
cat <<EOF > /vault/policies/dev-pol.hcl
path "secret/data/dev/\*" {
    capabilities = ["create", "read", "update", "delete", "list"]
}
EOF


# Apply policy
vault policy write <policy-name> <file-path>

#Apply policy admin to user admin
vault policy write admin admin-pol.hcl
vault write auth/userpass/users/admin \ 
    password=${SECRET_PASS} \
    policies=admin


## Prepare for Backup. Make sure you already logged in with root_token
vault auth enable userpass

# Write backup restore policy file
touch /vault/policies/backup-restore-pol.hcl

cat <<EOF > /vault/policies/backup-restore-pol.hcl
path "sys/storage/raft/*" {
    capabilities = ["create", "read", "update", "delete", "list"]
}
EOF

#Apply policy backup-restore
vault policy write backup-restore /vault/policies/backup-restore-pol.hcl

# Create user backup-restore
vault write auth/userpass/users/backup-restore \
    password=${BACKUP_RESTORE_PASS} \
    policies=backup-restore

#Run backup (change your VAULT_ADDR follow your URL in file /vault/bin/backup.sh)
chmod +x /vault/bin/backup.sh && /vault/bin/backup.sh


## Restore form backup
# Start another docker Vault following step prepare
# Restore form previous backup
vault login <root_token>
vault operator raft snapshot restore -force /vault/backup/<file-backup>

#Restart docker
# Access web app enter seal key
http://localhost:8200
# enter 3 seal key for unseal
# enter root_token for login





```
