# Jenkins Docker Setup Guide

This guide outlines the steps to set up Jenkins using Docker Compose on an Ubuntu machine.

## Prerequisites

- Ubuntu machine
- Root or sudo access

## Installation Steps

### 1. Update System and Install Docker

```bash
# Update package index and install Docker
sudo apt update -y
sudo apt install docker.io -y

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Set permissions and start Docker
sudo chmod 666 /var/run/docker.sock
sudo systemctl start docker
sudo systemctl enable docker

```

### 2. Create Jenkins Directory and Configuration Files
Create a new directory for Jenkins and navigate to it:

```bash
mkdir Jenkins && cd Jenkins
```

### 3. Create Dockerfile:

```Dockerfile
FROM ubuntu:22.04

RUN apt update && apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    docker.io \
    fish
```    

### 4. Create docker-compose.yml:

```docker
services:
  jenkins:
    image: jenkins/jenkins
    container_name: jenkins
    user: root
    privileged: true
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock

  ubuntu-slave:
    build:
      context: .
    container_name: ubuntu-slave
    volumes:
      - jenkins-slave-1-data:/var/lib/docker 

volumes:
  jenkins_home:
  jenkins-slave-1-data:
```

### 5. Start Jenkins
Run Docker Compose:

```bash
docker-compose up -d
```

Verify containers are running:

```bash
docker ps
```

### 6. Get Jenkins Initial Admin Password

Retrieve the initial admin password:

```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### Accessing Jenkins
### Open a web browser and navigate to http://your-server-ip:8080. Use the initial admin password to complete the setup process.