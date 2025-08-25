#!/usr/bin/python3
import os
import sys
from datetime import datetime
from pytz import timezone
from tzlocal import get_localzone
from pathlib import Path
import subprocess
import numpy as np
import uuid
import getopt


def get_local_time():
  # format = "%Y-%m-%d %H:%M:%S %Z%z"
  format = "%Y%m%d"
  now_utc = datetime.now(timezone('UTC'))
  # print(now_utc.strftime(format))
  now_local = now_utc.astimezone(get_localzone())
  local_time = now_local.strftime(format)
  return local_time


def create_snapshot(host, snapshot_name=get_local_time()):
  print("******** Start Create Snapshot ********")
  p = subprocess.Popen("nodetool -h %s snapshot -sf -t %s" % (host, snapshot_name),
                       stdout=subprocess.PIPE, shell=True, universal_newlines=True)
  print(p.communicate()[0])
  exitcode = p.wait()
  print("******** Success Create Snapshot With Return Code [%s]********" % (exitcode))


def get_list_path_keyspace(cassandra_data_path):
  system_keyspaces = ["system", "system_auth", "system_distributed", "system_schema", "system_traces"]
  return [os.path.join(cassandra_data_path, name) for name in os.listdir(cassandra_data_path)
          if os.path.isdir(os.path.join(cassandra_data_path, name)) and name not in system_keyspaces]


def get_list_keyspace(cassandra_data_path):
  system_keyspaces = ["system", "system_auth", "system_distributed", "system_traces", "system_schema"]
  return [name for name in os.listdir(cassandra_data_path)
          if os.path.isdir(os.path.join(cassandra_data_path, name)) and name not in system_keyspaces]


def get_list_snapshot_current_data(cassandra_data_path, snapshot_name=get_local_time()):
  if cassandra_data_path == "":
    print("ERROR: Can't found cassandra data")
    sys.exit(1)
  keyspaces = get_list_keyspace(cassandra_data_path)

  def get_tables(keyspace):
    keyspace_path = os.path.join(cassandra_data_path, keyspace)

    def split_table_name(table_name):
      split_name = str(table_name).split("-")
      name = split_name[0]
      name_hash = split_name[1]
      current_sstable = os.path.join(keyspace_path, table_name)
      snapshot_sstable = os.path.join(keyspace_path, "%s/snapshots/%s" % (table_name, snapshot_name))
      return dict(
        table_name=name,
        table_hash=name_hash,
        current_sstable=current_sstable,
        snapshot_sstable=snapshot_sstable
      )
    all_tables = [split_table_name(name) for name in os.listdir(keyspace_path)
                  if os.path.isdir(os.path.join(keyspace_path, name))]

    all_tables = sorted(all_tables, key=lambda x: uuid.UUID(x['table_hash']).time)

    # List table name in keyspace
    unique_tables = np.unique([item['table_name'] for item in all_tables])

    # List current table contain main data in keyspace
    current_tables = []
    for table in unique_tables:
      tab = [item for item in all_tables if item['table_name'] == table]
      tab = sorted(tab, key=lambda x: uuid.UUID(x['table_hash']).time)
      current_tables.append(tab[-1])
    return current_tables

  # List current table contain main data in all keyspace
  all_current_tables = dict()
  for keyspace in keyspaces:
    all_current_tables[keyspace] = get_tables(keyspace)
  return all_current_tables


def run(host, cassandra_data_path, snapshot_name=None, keyspaces=None, ex_keyspaces=None, tables=None, ex_tables=None):
  if not os.path.exists(cassandra_data_path):
    print("Can't stat cassandra data path: %s" % (cassandra_data_path))
    sys.exit(1)

  if snapshot_name != None:
    all_current_tables = get_list_snapshot_current_data(cassandra_data_path, snapshot_name)
    state = "snapshot_sstable"
  else:
    all_current_tables = get_list_snapshot_current_data(cassandra_data_path)
    state = "current_sstable"

  if ex_tables != None:
    ex_tables = ex_tables.split(',')
  else:
    ex_tables = []

  if ex_keyspaces != None:
    ex_keyspaces = ex_keyspaces.split(',')
  else:
    ex_keyspaces = []

  # Load all keyspaces
  if keyspaces == None and tables == None:
    print("Load all keyspaces")
    # stream all data
    print("<==========[Start Loading ...]==========>")
    for item in all_current_tables:
      if str(item) in ex_keyspaces:
        print("********* Ignore keyspace %s" % (str(item)))
        continue
      print("<==========[Start Load Keyspace: %s ]==========>" % (str(item)))
      sstables = all_current_tables[str(item)]
      for sstable in sstables:
        if sstable['table_name'] in ex_tables:
          print("******** Ignore table %s" % (sstable['table_name']))
          continue
        print("******** Start Load Table: %s" % (sstable['table_name']))
        print("DATA_PATH: %s" % (sstable[state]))
        p = subprocess.Popen("sstableloader -d %s %s" %
                             (host, sstable[state]), stdout=subprocess.PIPE, shell=True, universal_newlines=True)
        process_output, _ = p.communicate()
        exitcode = p.wait()
        print(process_output)
        print("End Load Table: %s with return code [%s]********" % (sstable['table_name'], exitcode))
      print("<==========[End Load KeySpace: %s ]==========>" % (str(item)))

  if tables != None and keyspaces == None:
    print("ERROR: Mising keyspace for tables")
    sys.exit(1)
  elif tables != None and len(keyspaces.split(',')) > 1:
    print("ERROR: Can't load mutiple tables for mutiple keyspaces")
    sys.exit(1)
  # Load tables in keyspace
  elif tables != None and len(keyspaces.split(',')) == 1:
    tables = tables.split(',')
    if keyspaces.split(',')[-1] not in all_current_tables:
      print("ERROR: Not exist keyspace %s" % (keyspaces.split(',')[-1]))
      sys.exit(1)
    print("<==========[Start Load Keyspace: %s ]==========>" % (keyspaces.split(',')[-1]))
    sstables = all_current_tables[keyspaces.split(',')[-1]]
    for table in tables:
      if table not in [item['table_name'] for item in sstables]:
        print("ERROR: Not exist table %s in keyspace %s" % (table, keyspaces.split(',')[-1]))
        continue
      sstable = sstables[sstables.index([item for item in sstables if item['table_name'] == table][-1])]
      print("******** Start Load Table: %s" % (table))
      print("DATA_PATH: %s" % (sstable[state]))
      p = subprocess.Popen("sstableloader -d %s %s" %
                           (host, sstable[state]), stdout=subprocess.PIPE, shell=True, universal_newlines=True)
      process_output, _ = p.communicate()
      exitcode = p.wait()
      print(process_output)
      print("End Load Table: %s with return code [%s]********" % (sstable['table_name'], exitcode))
    print("<==========[End Load KeySpace: %s ]==========>" % (keyspaces.split(',')[-1]))
  # Load keyspaces
  elif tables == None and keyspaces != None:
    keyspaces = keyspaces.split(',')
    for keyspace in keyspaces:
      if keyspace not in all_current_tables:
        print("ERROR: Not exist keyspace %s" % (keyspace))
        continue
      print("<==========[Start Load Keyspace: %s ]==========>" % (keyspace))
      sstables = all_current_tables[keyspace]
      for sstable in sstables:
        print("******** Start Load Table: %s" % (sstable['table_name']))
        print("DATA_PATH: %s" % (sstable[state]))
        p = subprocess.Popen("sstableloader -d %s %s" %
                             (host, sstable[state]), stdout=subprocess.PIPE, shell=True, universal_newlines=True)
        process_output, _ = p.communicate()
        exitcode = p.wait()
        print(process_output)
        print("End Load Table: %s with return code [%s]********" % (sstable['table_name'], exitcode))
      print("<==========[End Load KeySpace: %s ]==========>" % (keyspace))


def usage(argv):
  use = """Usage: \n"""
  use = use + """\t%s [options]\n\n""" % (argv)
  use = use + """options:\n\n"""
  use = use + """\t%-20s%-20s%-20s\n\n""" % ("KEY", "VALUE", "INFO")
  use = use + """\t%-20s%-20s%-20s\n\n""" % ("--help", "null", "Display help")
  use = use + """\t%-20s%-20s%-20s\n\n""" % ("-d | --data-path", "string",
                                             "Data path of cassandra (/var/lib/cassandra/data)")
  use = use + """\t%-20s%-20s%-20s\n\n""" % ("-s | --snapshot", "string",
                                             "Snapshot name to load (/var/lib/cassandra/data/keyspace/table/snapshots/snapshot)")
  use = use + """\t%-20s%-20s%-20s\n\n""" % ("-h | --host", "string", "Cassandra host to run")
  use = use + """\t%-20s%-20s%-20s\n\n""" % ("-k | --keyspace", "list comma string", "List keyspaces to load")
  use = use + """\t%-20s%-20s%-20s\n\n""" % ("-t | --table", "list comma string", "List tables to load")
  use = use + """\t%-20s%-20s%-20s\n\n""" % ("-e | --exclude", "list comma string", "list tables will be excluded")
  use = use + """\t%-20s%-20s%-20s\n\n""" % ("-i | --ignore", "list comma string", "list keyspaces will be ignore")
  use = use + """~~END~~"""
  print(use)


def read_opts():
  host = "localhost"
  data_path = ""
  snapshot_name = None
  keyspaces = None
  ex_keyspaces = None
  tables = None
  ex_tables = None
  src = sys.argv[0]
  argv = sys.argv[1:]
  try:
    opts, _ = getopt.gnu_getopt(argv, 'd:h:s:k:i:t:e:', [
                                'create-snapshot', 'help', 'data-path=', 'host=', 'snapshot=', 'keyspace=', 'table=', 'exclude=', 'ignore='])
    if len(opts) == 0:
      usage(src)
      sys.exit(1)
    for opt, arg in opts:
      if opt in ('-h', '--host'):
        host = arg
      if opt in ('-d', '--data-path'):
        data_path = arg
      if opt in ('-s', '--snapshot'):
        snapshot_name = arg
      if opt in ('-k', '--keyspace'):
        keyspaces = arg
      if opt in ('-t', '--table'):
        tables = arg
      if opt in ('-e', '--exclude'):
        ex_tables = arg
      if opt in ('-i', '--ignore'):
        ex_keyspaces = arg
      if opt == '--help':
        usage(src)
        sys.exit(0)
      if opt == '--create-snapshot':
        create_snapshot(host)
        sys.exit(0)
  except getopt.GetoptError:
    print('Something went wrong!')
    sys.exit(2)

  if data_path == "":
    print("Missing Data Path: use -d options")
    usage(src)
    sys.exit(1)

  run(host, data_path, snapshot_name, keyspaces, ex_keyspaces, tables, ex_tables)


if __name__ == '__main__':
  read_opts()
