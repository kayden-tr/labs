docker exec keycloak-keycloak/opt/bitnami/keycloak/bin/kc.sh export --dir /opt/bitnami/keycloak/data/ --users realm_file --realm master && \
docker cp keycloak-keycloak:/opt/bitnami/keycloak/data/master-realm.json ~/devops-tools/app/docker-run/keycloak && \
