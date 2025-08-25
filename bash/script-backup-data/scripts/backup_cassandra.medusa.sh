#!/bin/bash

# install cassandra-medusa from https://github.com/thelastpickle/cassandra-medusa/blob/master/docs/Installation.md

# for ubuntu/debian: config /etc/medusa/medusa.ini

# /etc/medusa/medusa/ini

# [cassandra]
# stop_cmd = /etc/init.d/cassandra stop
# start_cmd = /etc/init.d/cassandra start
# config_file = /etc/cassandra/cassandra.yaml
# cql_username = CQL_USERNAME
# cql_password = CQL_PASSWORD
# nodetool_username =  CASSANDRA_JMX_USERNAME
# nodetool_password =  CASSANDRA_JMX_PASSWORD
# ;nodetool_password_file_path = <path to nodetool password file>
# nodetool_host = localhost
# nodetool_port = 7199
# ;certfile= <Client SSL: path to rootCa certificate>
# ;usercert= <Client SSL: path to user certificate>
# ;userkey= <Client SSL: path to user key>
# ;sstableloader_ts = <Client SSL: full path to truststore>
# ;sstableloader_tspw = <Client SSL: password of the truststore>
# ;sstableloader_ks = <Client SSL: full path to keystore>
# ;sstableloader_kspw = <Client SSL: password of the keystore>
# ;sstableloader_bin = <Location of the sstableloader binary if not in PATH>
# ;nodetool_ssl = true
# ;check_running = nodetool version
# resolve_ip_addresses = True
# ;use_sudo = True

# [storage]
# storage_provider = local
# bucket_name = cassandra-medusa
# key_file = /etc/medusa/credentials
# base_path = /mnt/backup
# ;prefix = clusterA
# ;fqdn = <enforce the name of the local node. Computed automatically if not provided.>
# max_backup_age = 0
# max_backup_count = 0
# transfer_max_bandwidth = 50MB/s
# concurrent_transfers = 1
# multi_part_upload_threshold = 104857600
# backup_grace_period_in_days = 10
# use_sudo_for_restore = True
# ;api_profile = <AWS profile to use>
# ;host = <Optional object storage host to connect to>
# ;port = <Optional object storage port to connect to>
# ;secure = True
# ;aws_cli_path = <Location of the aws cli binary if not in PATH>

# [monitoring]
# ;monitoring_provider = <Provider used for sending metrics. Currently either of "ffwd" or "local">

# [ssh]
# ;username = <SSH username to use for restoring clusters>
# ;key_file = <Path of SSH key for use for restoring clusters. Expected in PEM unencrypted format.>
# ;port = <SSH port for use for restoring clusters. Default to port 22.
# ;cert_file = <Path of public key signed certificate file to use for authentication. The corresponding private key must also be provided via key_file parameter>

# [checks]
# ;health_check = <Which ports to check when verifying a node restored properly. Options are 'cql' (default), 'thrift', 'all'.>
# ;query = <CQL query to run after a restore to verify it went OK>
# ;expected_rows = <Number of rows expected to be returned when the query runs. Not checked if not specified.>
# ;expected_result = <Coma separated string representation of values returned by the query. Checks only 1st row returned, and only if specified>
# ;enable_md5_checks = <During backups and verify, use md5 calculations to determine file integrity (in addition to size, which is used by default)>

# [logging]
# ; enabled = 0
# ; file = medusa.log
# ; level = INFO
# ; format = [%(asctime)s] %(levelname)s: %(message)s
# ; maxBytes = 20000000
# ; backupCount = 50

# [grpc]
# ;enabled = False

# [kubernetes]
# ;enabled = False
# ;cassandra_url = <URL of the management API snapshot endpoint. For example: http://127.0.0.1:8080/api/v0/ops/node/snapshots>
# ;use_mgmt_api = True

DATE=$(date +%Y%m%d)

medusa backup --backup-name $DATE