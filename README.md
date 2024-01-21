# Configurer un **monitoring** avec Grafana, Prometheus, Node Exporter

Dans ce **README**, vous trouverez toutes les étapes pour configurer et installer un **monitoring** de base sur un système Linux à l'aide de Grafana, Prometheus et Node Exporter.

Pour commencer vous devez prealablement avoir installer docker sur votre machine

## Prérequis

Avant de commencer, assurez-vous d'avoir Docker installé sur votre machine. Si ce n'est pas déjà le cas, suivez les instructions appropriées pour l'installation de Docker.

## Monitoring

Le monitoring est divisé en trois parties.

-   **Grafana** s'occupera d'afficher, dans une page web, toutes les données collectées. Comme toutes les autres parties, Grafana fonctionne dans un conteneur Docker sur le port **:3000**.

-   **Prometheus** est le conteneur Docker qui condensera toutes les informations enregistrées par différents conteneurs tels que _Node Exporter_, _Cadvisor_, et les proposera à Grafana grâce notamment aux métriques. Les métriques sont toutes les informations disponibles, souvent sous la forme : **<initiale de l'exporteur><nom de la métrique>**. Ce sont ces métriques qui seront proposées à Grafana au moyen de l'API accessible sur le port **:9090**. Prometheus s'occupe aussi de stocker toutes les données. Il sauvegardera que les 2 dernières semaines, cette variable peut être modifiable dans les paramètres.

-   **Exporter** sont les conteneurs Docker qui s'occuperont chacun de leur côté de collecter leurs données et de les envoyer à Prometheus.

En plus des conteneurs **Grafana** et **Prometheus**, on a besoin de configurations, c'est pourquoi il y a des fichiers JSON de configuration.

-   **prometheus_main.yml** servira à indiquer les ports des exporteurs ainsi que leur nom et leur _scrape_interval_ qui est tous les combien de temps on ira chercher des données.

-   **dashboard** les tableaux de bord sont des fichiers JSON qui indiquent précisément où seront tous les blocs de données ainsi que leur format graphique, tableaux, etc.

-   **Provisioning** ce sont les fichiers qui indiquent la configuration de Grafana, comme à quel port trouver Prometheus et comment précharger les tableaux de bord.
