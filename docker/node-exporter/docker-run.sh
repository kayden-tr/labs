docker run -d \
  --net="host" \
  --pid="host" \
  -v "/:/host:ro,rslave" \
  --name devops-node-exporter \
  registry.atalink.com:10443/docker.io/prom/node-exporter:v1.8.0 \
  --path.rootfs=/host