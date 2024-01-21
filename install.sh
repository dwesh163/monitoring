#!/bin/bash

#Update
sudo apt update

#Install Docker
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
sudo apt-get update
sudo apt install -y docker-ce
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
docker network create monitoring
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
  -p 9101:8080 \
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

docker ps


