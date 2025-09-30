ui = true
api_addr = "http://127.0.0.1:8200"
cluster_addr = "http://127.0.0.1:8201"
plugin_directory = "/plugins"
disable_mlock = true

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
}

storage "raft" {
  path = "/vault/raft"
  node_id = "vault1"
}

log_level = "info"
log_file = "/vault/logs/vault.log"
log_rotate_max_files = 30