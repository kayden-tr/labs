#!/usr/bin/env python3

from cassandra.cluster import Cluster
from threading import Thread
from swiftclient.service import SwiftService
from dotenv import load_dotenv
import os
import datetime
import traceback

dir_path = os.path.dirname(os.path.realpath(__file__))
DOTENV_PATH = os.getenv('DOTENV_PATH', os.path.join(dir_path, '.env'))

backup_datetime = datetime.datetime.today().strftime("%Y-%m-%dT%H:%M:%S")
print("%s: DOTENV_PATH => '%s'" % (backup_datetime, DOTENV_PATH))

load_dotenv(dotenv_path=DOTENV_PATH, verbose=True, override=True)

# Getting files list from cassandra
cassandra_cluster_addresses = str.split(os.getenv('CASSANDRA_CLUSTER'), ',')
cassandra_cluster = Cluster(cassandra_cluster_addresses)
cassandra_session = cassandra_cluster.connect('bluesky_media')
rows = cassandra_session.execute(
    'SELECT storage_paths FROM bluesky_media.photo')

files = []
storage_paths = []

for row in rows:
    storage_paths.append(row[0])

for storage_path in storage_paths:
    if storage_path is not None:
        for image in storage_path:
            files.append(image)

# Configuring swift, keystone
os_auth_url = os.getenv('SWIFT_AUTH_URL')
os_username = os.getenv('SWIFT_USERNAME')
os_password = os.getenv('SWIFT_PASSWORD')
os_user_domain_name = os.getenv('SWIFT_USER_DOMAIN_NAME', 'default')
os_project_id = os.getenv('SWIFT_PROJECT_ID')
os_project_domain_name = os.getenv('SWIFT_PROJECT_DOMAIN_NAME', 'default')
os_container_name = os.getenv('SWIFT_CONTAINER_NAME')
os_region_name = os.getenv('SWIFT_REGION_NAME', 'RegionOne')

_opts = dict(
    auth_version="3",
    os_auth_url=os_auth_url,
    os_username=os_username,
    os_password=os_password,
    os_user_domain_name=os_user_domain_name,
    os_project_id=os_project_id,
    os_project_domain_name=os_project_domain_name,
    os_region_name=os_region_name
)

swift = SwiftService(_opts)

backup_date = datetime.datetime.today().strftime("%Y-%m-%d")

options = dict(
    out_directory=os.getenv(
        'SWIFT_DOWNLOAD_OUTPUT_DIR_PREFIX') + "/" + backup_date
)


def download(files_list=[]):
    try:
        for i in files_list:
            for down_res in swift.download(container=os_container_name, objects=[i.strip()], options=options):
                backup_datetime = datetime.datetime.today().strftime("%Y-%m-%dT%H:%M:%S")
                if down_res['success']:
                    print("%s: '%s' downloaded" %
                          (backup_datetime, down_res['object']))
                else:
                    reason = ""
                    if 'response_dict' in down_res and 'response_dicts' in down_res['response_dict']:
                        reason = down_res['response_dict']['response_dicts'][0]['reason']
                    print("%s: '%s' download failed, reason: %s" %
                          (backup_datetime, down_res['object'], reason))
                    if 'error' in down_res:
                        print(down_res['error'])
    except Exception:
        traceback.print_exc()


num_of_concurrent_threads = 2
num_files_per_thread = len(files) // 2
outer_list = []
thread_processes = []

current_threads_executing_count = 0

i = 0
while True:
    inner_list = files[i: i + num_files_per_thread]
    if (len(inner_list) == 0):
        break
    i = i + num_files_per_thread
    outer_list.append(inner_list)

for i in range(len(outer_list)):
    t = Thread(target=download, args=(outer_list[i],))
    t.start()
    thread_processes.append(t)

for process in thread_processes:
    process.join()
