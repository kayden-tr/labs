from cassandra.cluster import Cluster
from cassandra.auth import PlainTextAuthProvider

username  = 'cassandra'
password = '123QWEasd@?!'
auth_provider = PlainTextAuthProvider(username=username, password=password)

cluster = Cluster(['172.16.7.171'], auth_provider=auth_provider)
session = cluster.connect()
if session:
    print("Connection successful")
else:
    print("Failed")
rows = session.execute("SELECT keyspace_name  FROM system_schema.keyspaces;")
for row in rows:
    print(row.keyspace_name)


