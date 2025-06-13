# Installing Docker & Docker Compose on Linux

This guide provides instructions for installing Docker and Docker Compose on Ubuntu and CentOS systems.

## Ubuntu Installation
Follow these steps to install Docker and Docker Compose on Ubuntu:

```bash
sudo apt update -y
sudo apt install fish docker.io -y
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo chmod 666 /var/run/docker.sock
sudo systemctl start docker
sudo systemctl enable docker
```

### CentOS Installation
Follow these steps to install Docker and Docker Compose on CentOS:

```bash
sudo yum update -y
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo systemctl start docker
sudo systemctl enable docker
```