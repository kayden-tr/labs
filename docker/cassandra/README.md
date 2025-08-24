## Start container
cp env.template .env
docker compose up -d 

## Change password CQLSH
```bash
export CASSANDRA_PASSWORD=<your-password> \
docker exec -it <container-name> bash -c 'cqlsh -u cassandra -p cassandra -e "ALTER USER cassandra WITH PASSWORD '\''$CASSANDRA_PASSWORD'\'';"'
```