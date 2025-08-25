#!/usr/bin/env python3
#
# Find or delete files in S3 older than a given age and matching a pattern
# Useful for cleaning up old backups, etc.
#

import boto3
import time
from datetime import datetime
from optparse import OptionParser
import sys
import re


def main(args):
    parser = OptionParser()
    # AWS_PROFILE env
    # AWS_ACCESS_KEY_ID env
    parser.add_option("--key", dest="key", metavar="KEY",
                      help="AWS Access Key")
    # AWS_SECRET_ACCESS_KEY env
    parser.add_option("--secret", dest="secret", metavar="SECRET",
                      help="AWS Access Secret Key")
    parser.add_option("--maxage", dest="maxage", metavar="SECONDS",
                      help="Max age a key(file) can have before we want to delete it")
    parser.add_option("--regex", dest="regex", metavar="REGEX",
                      help="Only consider keys matching this REGEX")
    parser.add_option("--bucket", dest="bucket", metavar="BUCKET",
                      help="Search for keys in a specific bucket")
    parser.add_option("--delete", dest="delete", metavar="REGEX", action="store_true",
                      default=False, help="Actually do a delete. If not specified, just list the keys found that match.")
    (config, args) = parser.parse_args(args)

    config_ok = True
    for flag in ["bucket"]:
        if getattr(config, flag) is None:
            print("ERROR: missing required flag: --%s" % flag)
            config_ok = False

    if not config_ok:
        print("ERROR: configuration is not ok, aborting...")
        return 1

    s3 = boto3.client(
        's3',
        aws_access_key_id=config.key,
        aws_secret_access_key=config.secret,
    )

    # 30d
    config.maxage = int(config.maxage or 2592000)

    if config.regex:
        config.regex = re.compile(config.regex)

    current_year = datetime.now().year

    root_objects = s3.list_objects_v2(
        Bucket=config.bucket,
        Prefix='%s/' % (current_year),
        Delimiter='/',
        MaxKeys=100
    )

    deleted_objects = []

    for key in root_objects.get('CommonPrefixes'):
        deleted_objects_per_path = []
        backup_objects = s3.list_objects_v2(
            Bucket=config.bucket,
            Prefix=key["Prefix"],
            Delimiter='/',
            MaxKeys=100
        )

        if not "Contents" in backup_objects:
            print("INFO: skip due to no objects in path %s" % (key["Prefix"]))
            continue

        total_objects_per_path = len(backup_objects["Contents"])
        print("INFO: total_objects_per_path => %s, path => %s" %
              (total_objects_per_path, key["Prefix"]))

        if total_objects_per_path <= 30:
            print("INFO: skip due to total_objects_per_path <= 30, path => %s" %
                  (key["Prefix"]))
            continue

        for backup in backup_objects["Contents"]:
            mtime = backup["LastModified"].timestamp()
            now = time.time()
            if mtime > (now - config.maxage):
                print("INFO: keeping s3://%s/%s" %
                      (config.bucket, backup["Key"]))
                continue
            if config.regex and config.regex.search(backup["Key"]) is None:
                continue
            if config.delete:
                print("INFO: deleting s3://%s/%s" %
                      (config.bucket, backup["Key"]))
                print("    reason => object has age %d, older than --maxage %d" %
                      (now - mtime, config.maxage))
                # print("    reason => key matches pattern /%s/" % (config.regex.pattern))
                deleted_objects.append({
                    "Key": backup["Key"]
                })

                deleted_objects_per_path.append({
                    "Key": backup["Key"]
                })

                if total_objects_per_path - len(deleted_objects_per_path) <= 30:
                    print(
                        "INFO: skip next objects due to (total_objects_per_path - len(deleted_objects_per_path)) <= 30, path => %s" % (key["Prefix"]))
                    break
            else:
                print("INFO: will delete s3://%s/%s" %
                      (config.bucket, backup["Key"]))
                print("    reason => object has age %d, older than --maxage %d" %
                      (now - mtime, config.maxage))

    if len(deleted_objects) > 0:
        delete_result = s3.delete_objects(
            Bucket=config.bucket,
            Delete={
                "Objects": deleted_objects,
                "Quiet": False
            }
        )

        if "Errors" in delete_result:
            print(delete_result["Errors"])
    else:
        print("INFO: no objects is deleted")


if __name__ == '__main__':
    sys.exit(main(sys.argv))
