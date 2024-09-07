#!/bin/bash

#Update
sudo apt update

#Install Docker
sudo apt-get -y install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

#Add user to Docker group
sudo groupadd docker
sudo usermod -aG docker $USER

echo "Docker has been successfully installed."

#creating folders for Docker
mkdir "grafana"
chmod 777 "grafana"
mkdir "grafana/data"
chmod 777 "grafana/data"
echo "Grafana Folders created."

mkdir "prometheus"
chmod 777 "prometheus"
mkdir "prometheus/data"
chmod 777 "prometheus/data"
echo "Prometheus Folders created."


# Copy data
cp -r "files/grafana/"* "grafana"
cp "files/prometheus_main.yml" "prometheus/prometheus.yml"

echo "File copied."

#create network
sudo docker network create monitoring
echo "network monitoring created"

#Run Docker
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

echo "cAdvisor container started."

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

echo "Grafana container started."

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
  --path.sysfs=/host/sys \

echo "Node Exporter container started."

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
  --web.enable-lifecycle \

echo "Prometheus container started."

sudo docker run -d \
  --name nodered \
  --restart always \
  -p 1880:1880 \
  -v "$(pwd)"/nodered:/data \
  nodered/node-red
echo "Node-Red container started."

sudo docker network create moodle-network
echo "Moodle network created."

mkdir "moodle"
chmod 777 "moodle"
mkdir "moodle/mariadb"
chmod 777 "moodle/mariadb"
mkdir "moodle/moodle"
chmod 777 "moodle/moodle"
mkdir "moodle/moodledata"
chmod 777 "moodle/moodledata"
echo "Moodle Folders created."

sudo docker run -d \
  --name mariadb \
  --env ALLOW_EMPTY_PASSWORD=yes \
  --env MARIADB_USER=bn_moodle \
  --env MARIADB_PASSWORD=bitnami \
  --env MARIADB_DATABASE=bitnami_moodle \
  --network moodle-network \
  -v "$(pwd)"/moodle/mariadb:/bitnami/mariadb \
  bitnami/mariadb:latest

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
echo "Moodle containers started."

sudo docker run -d \
  -name traefik \
  -p 80:80 -p 8080:8080 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  traefik:v2.5
echo "Traefik container started."

sudo docker ps


