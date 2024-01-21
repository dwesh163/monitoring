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
mkdir "grafana/data"
echo "Grafana Folder created."
mkdir "prometheus"
mkdir "prometheus/data"
echo "Prometheus Folder created."

# Copy data
cp -r "files/grafana/"* "grafana"
cp "files/prometheus_main.yml" "prometheus/prometheus.yml"

echo "File copied."

#Run Docker
docker run -d \
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

docker run -d \
  --name grafana \
  --restart always \
  --network monitoring \
  -v /srv/grafana/data:/var/lib/grafana \
  -v /srv/grafana/provisioning:/etc/grafana/provisioning \
  -v /srv/grafana/dashboards:/var/lib/grafana/dashboards \
  -e GF_AUTH_ANONYMOUS_ENABLED=true \
  -e GF_AUTH_ANONYMOUS_ORG_ROLE=Admin \
  -p 3000:3000 \
  grafana/grafana

echo "Grafana container started."

docker run -d \
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
  --collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)

echo "Node Exporter container started."

docker run -d \
  --name prometheus \
  --restart always \
  --network monitoring \
  -v /srv/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
  -v /srv/prometheus/prometheus_alerts_rules.yml:/etc/prometheus/rules/prometheus_alerts_rules.yml \
  -v /srv/prometheus/data:/prometheus \
  prom/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.console.templates=/etc/prometheus/consoles \
  --web.enable-lifecycle \
  -p 9090:9090

echo "Prometheus container started."


