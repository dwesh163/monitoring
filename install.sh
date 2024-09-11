#!/bin/bash

# Création des dossiers pour Docker avec des permissions adaptées aux utilisateurs des conteneurs
sudo mkdir -p "grafana/data"
echo "Dossiers Grafana créés avec permissions adaptées."

sudo mkdir -p "prometheus/data"
echo "Dossiers Prometheus créés avec permissions adaptées."

sudo mkdir -p "nodered"
echo "Dossier Node-Red créé avec permissions adaptées."

sudo mkdir -p "moodle/mariadb" "moodle/moodle" "moodle/moodledata"
echo "Dossiers Moodle créés avec permissions adaptées."

# Copier les fichiers
sudo cp -r "files/grafana/"* "grafana"
sudo cp "files/prometheus_main.yml" "prometheus/prometheus.yml"
echo "Fichiers copiés."

# Donne tous les droits au propriétaire, lecture/écriture/exécution pour le groupe, lecture/exécution pour les autres
sudo chmod -R 755 grafana prometheus nodered moodle

# Assurez-vous que les dossiers appartiennent aux bons utilisateurs du conteneur Docker
sudo chown -R 472:472 grafana        # Utilisateur Grafana (UID 472)
sudo chown -R nobody:nogroup prometheus # Utilisateur Prometheus (généralement nobody)
sudo chown -R 1000:1000 nodered       # Utilisateur Node-RED (UID 1000)
sudo chown -R 1001:1001 moodle        # Utilisateur Moodle (Bitnami UID 1001)


# Créer un réseau pour la surveillance
docker network create monitoring
echo "Réseau monitoring créé."

# Lancer les conteneurs Docker

# cAdvisor
sudo docker run -d \
  --name cadvisor \
  --restart always \
  --network monitoring \
  -v /:/rootfs:ro \
  -v /var/run:/var/run:ro \
  -v /sys:/sys:ro \
  -v /var/lib/docker/:/var/lib/docker:ro \
  -v /dev/disk/:/dev/disk:ro \
  zcube/cadvisor
echo "Conteneur cAdvisor démarré."

# Grafana
sudo docker run -d \
  --name grafana \
  --restart always \
  --network monitoring \
  -v "$(pwd)"/grafana/data:/var/lib/grafana \
  -v "$(pwd)"/grafana/provisioning:/etc/grafana/provisioning \
  -v "$(pwd)"/grafana/dashboards:/var/lib/grafana/dashboards \
  -e GF_AUTH_ANONYMOUS_ENABLED=true \
  -e GF_AUTH_ANONYMOUS_ORG_ROLE=Admin \
  -p 3000:3000 \
  grafana/grafana-enterprise
echo "Conteneur Grafana démarré."

# Node Exporter
sudo docker run -d \
  --name node-exporter \
  --restart always \
  --network monitoring \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /:/rootfs:ro \
  prom/node-exporter \
  --path.procfs=/host/proc \
  --path.rootfs=/rootfs \
  --path.sysfs=/host/sys
echo "Conteneur Node Exporter démarré."

# Prometheus
sudo docker run -d \
  --name prometheus \
  --restart always \
  --network monitoring \
  -p 9090:9090 \
  -v "$(pwd)"/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
  -v "$(pwd)"/prometheus/data:/prometheus \
  prom/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.console.templates=/etc/prometheus/consoles \
  --web.enable-lifecycle
echo "Conteneur Prometheus démarré."

# Node-Red
sudo docker run -d \
  --name nodered \
  --restart always \
  -p 1880:1880 \
  -v "$(pwd)"/nodered:/data \
  nodered/node-red
echo "Conteneur Node-Red démarré."

# Créer un réseau pour Moodle
docker network create moodle-network
echo "Réseau Moodle créé."

# MariaDB pour Moodle
sudo docker run -d \
  --name mariadb \
  --env ALLOW_EMPTY_PASSWORD=yes \
  --env MARIADB_USER=bn_moodle \
  --env MARIADB_PASSWORD=bitnami \
  --env MARIADB_DATABASE=bitnami_moodle \
  --network moodle-network \
  -v "$(pwd)"/moodle/mariadb:/bitnami/mariadb \
  bitnami/mariadb:latest

# Moodle
sudo docker run -d \
  --name moodle \
  -p 3030:8080 -p 8443:8443 \
  --env ALLOW_EMPTY_PASSWORD=yes \
  --env MOODLE_DATABASE_USER=bn_moodle \
  --env MOODLE_DATABASE_PASSWORD=bitnami \
  --env MOODLE_DATABASE_NAME=bitnami_moodle \
  --network moodle-network \
  -v "$(pwd)"/moodle/moodle:/bitnami/moodle \
  -v "$(pwd)"/moodle/moodledata:/bitnami/moodledata \
  bitnami/moodle:latest
echo "Conteneurs Moodle démarrés."

# Traefik
sudo docker run -d \
  --name traefik \
  -p 80:80 -p 8080:8080 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  traefik:v2.5
echo "Conteneur Traefik démarré."

# Afficher les conteneurs en cours d'exécution
docker ps
