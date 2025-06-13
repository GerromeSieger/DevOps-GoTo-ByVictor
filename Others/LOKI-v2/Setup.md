# Loki Grafana and Promtail Logging Stack with Docker Compose

This guide provides step-by-step instructions for setting UP Loki Grafana and Promtail using Docker Compose:

## Prerequisites

- Docker and Docker Compose installed on your host machine
- Basic understanding of Docker and containerization concepts

## Steps

1. Create a folder and other sub-folders to be working in:

```bash
mkdir -p LokiGrafana/promtail LokiGrafana/loki
```

2. Create a file named `docker-compose.yml` in the created main folder:

```bash
cd LokiGrafana
nano docker-compose.yml
```

3. Create a file named `promtail-config.yml` in the promtail sub-folder:

```bash
nano promtail/promtail-config.yml
```

4. Create a file named `loki-config.yml` in the loki sub-folder:

```bash
nano loki/loki-config.yml
```

5. Start containers 

```bash
docker-compose up -d
```

6. Install the Loki plugin:

```bash
docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions
```

7. Create a file named `daemon.json` in the /etc/docker folder:

```bash
sudo nano /etc/docker/daemon.json
```

8. Restart containers 

```bash
docker-compose up -d --force-recreate
```

9. Open up Grafana's ui on http://ipaddress:3000