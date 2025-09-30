# prom in docker

## How to start prometheus

```bash
cp env.template .env

# edit .env
vim .env

chown -R 1001:1001 ./config
chown -R 1001:1001 ./rules

docker compose up -d
```
